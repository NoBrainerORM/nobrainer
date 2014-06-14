class NoBrainer::QueryRunner::TableOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if NoBrainer::Config.auto_create_tables &&
       e.message =~ /^Table `(.+)\.(.+)` does not exist\.$/
      auto_create_table(env, $1, $2)
      retry
    end
    raise
  end

  private

  def auto_create_table(env, database_name, table_name)
    klass = NoBrainer::Document.all.select { |m| m.table_name == table_name }.first
    if klass.nil?
      raise "Auto table creation is not working for `#{database_name}.#{table_name}` -- Can't find the corresponding model."
    end

    if env[:auto_create_table] == [database_name, table_name]
      raise "Auto table creation is not working for `#{database_name}.#{table_name}`"
    end
    env[:auto_create_table] = [database_name, table_name]

    NoBrainer.with_database(database_name) do
      NoBrainer.table_create(table_name, :primary_key => klass.pk_name)
    end
  rescue RuntimeError => e
    # We might have raced with another table create
    raise unless e.message =~ /Table `#{database_name}\.#{table_name}` already exists/
  end
end
