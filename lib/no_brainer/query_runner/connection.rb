class NoBrainer::QueryRunner::Connection < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError, NoBrainer::Error::DocumentNotSaved => err
    if err.message =~ /cannot perform (read|write): lost contact with master/
      env[:connection_retries] ||= 0
      # TODO sleep in between? timing out should be time based?

      # XXX Possibly dangerous, as we could reexecute a non idempotent operation
      # Check the semantics of the db

      # TODO Unit test
      retry if (env[:connection_retries] += 1) < 10
    end
    raise err
  end
end
