class NoBrainer::QueryRunner::DatabaseOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if database_name = handle_database_on_demand_exception?(env, e)
      auto_create_database(env, database_name)
      retry
    end
    raise
  end

  def handle_database_on_demand_exception?(env, e)
    (NoBrainer::Config.auto_create_databases || env[:auto_create_databases]) &&
    e.message =~ /^Database `(.+)` does not exist\.$/ && $1
  end

  private

  def auto_create_database(env, database_name)
    if env[:last_auto_create_database] == database_name
      raise "Auto database creation is not working with #{database_name}"
    end
    env[:last_auto_create_database] = database_name

    NoBrainer.db_create(database_name)
  rescue RuntimeError => e
    # We might have raced with another db_create
    raise unless e.message =~ /Database `#{database_name}` already exists/
  end
end
