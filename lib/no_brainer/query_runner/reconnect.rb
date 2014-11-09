class NoBrainer::QueryRunner::Reconnect < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue StandardError => e
    context ||= { :retries => NoBrainer::Config.max_retries_on_connection_failure }
    if is_connection_error_exception?(e)
      if NoBrainer::Config.max_retries_on_connection_failure == 0
        NoBrainer.disconnect
      else
        # XXX Possibly dangerous, as we could reexecute a non idempotent operation
        # Check the semantics of the db
        retry if reconnect(e, context)
      end
    end
    raise
  end

  private

  def reconnect(e, context)
    return false if context[:retries].zero?
    context[:retries] -= 1

    warn_reconnect(e)
    sleep 1
    NoBrainer.connection.reconnect(:noreply_wait => false)
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
      e.message =~ /No master available/ ||
      e.message =~ /Master .* not available/ ||
      e.message =~ /Error: Connection Closed/
    else
      false
    end
  end

  def warn_reconnect(e)
    if e.is_a?(RethinkDB::RqlRuntimeError)
      e_msg = e.message.split("\n").first
      msg = "Server #{NoBrainer::Config.rethinkdb_url} not ready - #{e_msg}, retrying..."
    else
      msg = "Connection issue with #{NoBrainer::Config.rethinkdb_url} - #{e}, retrying..."
    end
    NoBrainer.logger.try(:warn, msg)
  end
end
