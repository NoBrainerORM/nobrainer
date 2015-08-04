class NoBrainer::QueryRunner::Reconnect < NoBrainer::QueryRunner::Middleware
  def call(env)
    current_connection = NoBrainer.connection
    @runner.call(env)
  rescue StandardError => e
    if is_connection_error_exception?(e)
      context ||= {:connection_retries => max_tries,
                   :previous_connection => current_connection}
      # XXX Possibly dangerous, as we could reexecute a non idempotent operation

      should_retry = synchronize do
        current_connection != NoBrainer.connection || # someone else got to reconnect
          reconnect(e, context)
      end
      retry if should_retry
    end
    raise
  end

  private

  # XXX Having a connection pool would make everything much better!!
  # TODO Refactor

  def max_tries
    NoBrainer::Config.max_retries_on_connection_failure
  end

  def synchronize(&block)
    case NoBrainer::Config.driver
      when :regular then block.call # we already have a lock from the connection_lock middleware
      when :em      then self.class.em_mutex.synchronize(&block)
    end
  end

  def self.em_mutex
    @lock ||= EM::Synchrony::Thread::Mutex.new
  end

  def reconnect(e, context)
    NoBrainer.disconnect

    unless context[:lost_connection_logged]
      context[:lost_connection_logged] = true

      msg = server_not_ready?(e) ? "Server %s not ready: %s" : "Connection issue with %s: %s"
      NoBrainer.logger.warn(msg % [context[:previous_connection].try(:uri), exception_msg(e)])
    end

    if context[:connection_retries].zero?
      NoBrainer.logger.info("Retry limit exceeded (#{max_tries}). Giving up.")
      return false
    end
    context[:connection_retries] -= 1

    case NoBrainer::Config.driver
    when :regular then sleep 1
    when :em      then EM::Synchrony.sleep 1
    end

    c = NoBrainer.connection
    NoBrainer.logger.info("Connecting to #{c.uri}... (last error: #{exception_msg(e)})")
    c.connect

    true
  rescue StandardError => e
    retry if is_connection_error_exception?(e)
    raise
  end

  def is_connection_error_exception?(e)
    case e
    when Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EPIPE,
      Errno::ECONNRESET, Errno::ETIMEDOUT, IOError
      true
    when RethinkDB::RqlRuntimeError
      e.message =~ /lost contact/ ||
      e.message =~ /(P|p)rimary .* not available/||
      e.message =~ /Connection.*closed/
    else
      false
    end
  end

  def exception_msg(e)
    e.is_a?(RethinkDB::RqlRuntimeError) ? e.message.split("\n").first : e.to_s
  end

  def server_not_ready?(e)
    e.message =~ /lost contact/ ||
    e.message =~ /(P|p)rimary .* not available/
  end
end
