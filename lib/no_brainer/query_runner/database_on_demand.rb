class NoBrainer::QueryRunner::DatabaseOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => err
    if err.message =~ /^Database `(.+)` does not exist\.$/
      # RethinkDB may return an FIND_DB not found immediately
      # after having created the new database, Be patient.
      # TODO Unit test that thing
      # Also, should we be counter based, or time based for the timeout ?
      NoBrainer.db_create $1 unless retries
      retries ||= 0
      retry if (env[:db_find_retries] += 1) < 10
    end
    raise err
  end

  private
  def retries
    env[:db_find_retries]
  end
end
