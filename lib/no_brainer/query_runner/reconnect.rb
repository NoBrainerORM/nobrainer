class NoBrainer::QueryRunner::Reconnect < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue StandardError => e
    # TODO test that thing
    if is_connection_error_exception?(e)
      retry if reconnect(e)
    end
    raise
  end

  private

  def reconnect(e)
    # FIXME thread safety? perhaps we need to use a connection pool
    # XXX Possibly dangerous, as we could reexecute a non idempotent operation
    # Check the semantics of the db
    NoBrainer::Config.max_reconnection_tries.times do
      begin
        warn_reconnect(e)
        sleep 1
        NoBrainer.connection.reconnect(:noreply_wait => false)
        return true
      rescue StandardError => e
        retry if is_connection_error_exception?(e)
        raise
      end
    end
    false
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
