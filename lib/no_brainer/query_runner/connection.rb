class NoBrainer::QueryRunner::Connection < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue StandardError => e
    # TODO test that thing
    if is_connection_error_exception?(e)
      retry if reconnect
    end
    raise
  end

  private

  def reconnect
    # FIXME thread safety? perhaps we need to use a connection pool
    # XXX Possibly dangerous, as we could reexecute a non idempotent operation
    # Check the semantics of the db
    NoBrainer::Config.max_reconnection_tries.times do
      begin
        NoBrainer.logger.try(:warn, "Lost connection to #{NoBrainer::Config.rethinkdb_url}, retrying...")
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
      e.message =~ /cannot perform (read|write): No master available/ ||
      e.message =~ /Error: Connection Closed/
    else
      false
    end
  end
end
