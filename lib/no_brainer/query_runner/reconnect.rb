class NoBrainer::QueryRunner::Reconnect < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue StandardError => e
    NoBrainer.disconnect if is_connection_error_exception?(e)
    raise
  end

  private

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
end
