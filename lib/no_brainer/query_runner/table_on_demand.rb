class NoBrainer::QueryRunner::TableOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if table_info = handle_table_on_demand_exception?(env, e)
      auto_create_table(env, *table_info)
      retry
    end
    raise
  end

  def handle_table_on_demand_exception?(env, e)
    e.message =~ /^Table `(.+)\.(.+)` does not exist\.$/ && [$1, $2]
  end

  private

  def auto_create_table(env, db_name, table_name)
    model = NoBrainer::Document.all(:types => [:user, :nobrainer])
                               .detect { |m| m.table_name == table_name }
    if model.nil?
      raise "Auto table creation is not working for `#{db_name}.#{table_name}` -- Can't find the corresponding model."
    end

    if env[:last_auto_create_table] == [db_name, table_name]
      raise "Auto table creation is not working for `#{db_name}.#{table_name}`"
    end
    env[:last_auto_create_table] = [db_name, table_name]

    create_options = model.table_create_options

    NoBrainer.run(:db => db_name) do |r|
      r.table_create(table_name, create_options.reject { |k,_| k.in? [:name, :write_acks] })
    end

    if create_options[:write_acks] && create_options[:write_acks] != 'single'
      NoBrainer.run(:db => db_name) do |r|
        r.table(table_name).config().update(:write_acks => create_options[:write_acks])
      end
    end
  rescue RuntimeError => e
    # We might have raced with another table create
    raise unless e.message =~ /Table `#{db_name}\.#{table_name}` already exists/
  end
end
