class NoBrainer::QueryRunner::Reconnect < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue StandardError => e
    if is_connection_error_exception?(e)
      context ||= {}
      # XXX Possibly dangerous, as we could reexecute a non idempotent operation
      retry if reconnect(e, context)
    end
    raise
  end

  private

  def max_tries
    NoBrainer::Config.max_retries_on_connection_failure
  end

  def reconnect(e, context)
    context[:connection_retries] ||= max_tries
    context[:previous_connection] ||= NoBrainer.connection
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

    sleep 1

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
