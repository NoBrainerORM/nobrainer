module NoBrainer::QueryRunner::DatabaseOnDemand
  def run(env)
    super
  rescue RuntimeError => e
    if e.message =~ /`FIND_DB (.+)`: No entry with that name/
      # RethinkDB may return an FIND_DB not found immediately
      # after having created the new database, Be patient.
      # TODO Unit test that thing
      # Also, should we be counter based, or time based for the timeout ?
      NoBrainer.db_create $1 unless env[:db_find_retries]
      env[:db_find_retries] ||= 0
      retry if (env[:db_find_retries] += 1) < 10
    end
    raise e
  end
end
