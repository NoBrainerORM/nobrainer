class NoBrainer::QueryRunner::RunOptions < NoBrainer::QueryRunner::Middleware
  def self.with_database(db_name, &block)
    STDERR.puts "[NoBrainer] `with_database()' is deprecated, please use `with(db: ...)' instead"
    with(:db => db_name, &block)
  end

  def self.with(options={}, &block)
    STDERR.puts "[NoBrainer] `with(...)' is deprecated, please use `run_with(...)' instead"
    run_with(options, &block)
  end

  def self.current_run_options
    Thread.current[:nobrainer_run_with] || {}
  end

  def self.run_with(options={}, &block)
    options = options.symbolize_keys

    if options[:database]
      STDERR.puts "[NoBrainer] `run_with(database: ...)' is deprecated, please use `run_with(db: ...)' instead"
      options[:db] = options.delete(:database)
    end

    old_options = Thread.current[:nobrainer_run_with]
    Thread.current[:nobrainer_run_with] = (old_options || {}).merge(options)
    block.call
  ensure
    Thread.current[:nobrainer_run_with] = old_options
  end

  def call(env)
    options = env[:options].symbolize_keys
    options = self.class.current_run_options.merge(options)

    if NoBrainer::Config.durability.to_s != 'hard'
      options[:durability] ||= NoBrainer::Config.durability
    end

    options[:db] = options[:db].to_s if options[:db]
    if options[:db].blank? || options[:db] == NoBrainer.default_db
      options.delete(:db)
    end

    env[:criteria] = options.delete(:criteria)

    env[:options] = options
    @runner.call(env)
  end
end
