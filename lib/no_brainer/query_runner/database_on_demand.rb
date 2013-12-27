class NoBrainer::QueryRunner::DatabaseOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if NoBrainer::Config.auto_create_databases &&
       e.message =~ /^Database `(.+)` does not exist\.$/
      auto_create_database(env, $1)
      retry
    end
    raise
  end

  private

  def auto_create_database(env, database_name)
    if env[:auto_create_database] == database_name
      raise "Auto database creation is not working with #{database_name}"
    end
    env[:auto_create_database] = database_name

    NoBrainer.db_create(database_name)
  rescue RuntimeError => e
    # We might have raced with another db_create
    raise unless e.message =~ /Database `#{database_name}` already exists/
  end
end
