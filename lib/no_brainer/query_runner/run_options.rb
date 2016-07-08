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
    options = NoBrainer::Config.run_options
    options = options.merge(:durability => NoBrainer::Config.durability) if NoBrainer::Config.durability
    options = options.merge(Thread.current[:nobrainer_run_with]) if Thread.current[:nobrainer_run_with]
    options
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
    options = self.class.current_run_options
    options = options.merge(env[:options].symbolize_keys)
    options = prune_default_run_options(options)

    env[:criteria] = options.delete(:criteria)

    if options[:profile] && env[:criteria].try(:raw?) == false
      STDERR.puts "[NoBrainer]"
      STDERR.puts "[NoBrainer]\e[1;31m Please use `.raw' in your criteria when profiling\e[0m"
      STDERR.puts "[NoBrainer]"
    end

    env[:options] = options
    @runner.call(env)
  end

  def prune_default_run_options(options)
    options = options.dup
    options.delete(:durability) if options[:durability].to_s == 'hard'

    options[:db] = options[:db].to_s if options[:db]
    options.delete(:db) if options[:db].blank? || options[:db] == NoBrainer.default_db

    options
  end
end
