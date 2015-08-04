class NoBrainer::QueryRunner::DatabaseOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if db_name = handle_database_on_demand_exception?(env, e)
      auto_create_database(env, db_name)
      retry
    end
    raise
  end

  def handle_database_on_demand_exception?(env, e)
    e.message =~ /^Database `(.+)` does not exist\.$/ && $1
  end

  private

  def auto_create_database(env, db_name)
    if env[:last_auto_create_database] == db_name
      raise "Auto database creation is not working with #{db_name}"
    end
    env[:last_auto_create_database] = db_name

    NoBrainer.run { |r| r.db_create(db_name) }
  rescue RethinkDB::RqlRuntimeError => e
    # We might have raced with another db_create
    raise unless e.message =~ /Database `#{db_name}` already exists/
  end
end
