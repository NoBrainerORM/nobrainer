class NoBrainer::QueryRunner::RunOptions < NoBrainer::QueryRunner::Middleware
  def self.with_database(db_name, &block)
    STDERR.puts "[NoBrainer] `with_database()' is deprecated, please use `with(db: ...)' instead"
    with(:db => db_name, &block)
  end

  def self.with(options={}, &block)
    STDERR.puts "[NoBrainer] `with(...)' is deprecated, please use `run_with(...)' instead"
    run_with(options, &block)
  end

  def self.run_with(options={}, &block)
    options = options.symbolize_keys

    if options[:database]
      STDERR.puts "[NoBrainer] `run_with(database: ...)' is deprecated, please use `run_with(db: ...)' instead"
      options[:db] = options.delete(:database)
    end

    options[:db] = options[:db].to_s if options[:db].is_a?(Symbol)

    old_options = Thread.current[:nobrainer_options]
    # XXX NoBrainer::Connection#current_db() uses Thread.current[:nobrainer_options]
    Thread.current[:nobrainer_options] = (old_options || {}).merge(options)
    block.call.tap { |ret| raise "use `run_with()' directly in your query" if ret.is_a?(NoBrainer::Criteria) }
  ensure
    Thread.current[:nobrainer_options] = old_options
  end

  def call(env)
    env[:options] = env[:options].symbolize_keys
    if Thread.current[:nobrainer_options]
      env[:options] = Thread.current[:nobrainer_options].merge(env[:options])
    end

    if NoBrainer::Config.durability.to_s != 'hard'
      env[:options] = { :durability => NoBrainer::Config.durability }.merge(env[:options])
    end

    env[:criteria] = env[:options].delete(:criteria)

    if env[:options][:db].nil? || env[:options][:db] == NoBrainer.default_db
      env[:options].delete(:db)
    end

    @runner.call(env)
  end
end
