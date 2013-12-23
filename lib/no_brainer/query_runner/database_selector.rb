class NoBrainer::QueryRunner::DatabaseSelector < NoBrainer::QueryRunner::Middleware
  # XXX NoBrainer::Database#drop() uses Thread.current[:nobrainer_database]

  def self.with_database(db, &block)
    old_db, Thread.current[:nobrainer_database] = Thread.current[:nobrainer_database], db
    block.call if block
  ensure
    Thread.current[:nobrainer_database] = old_db
  end

  def call(env)
    if Thread.current[:nobrainer_database]
      db = RethinkDB::RQL.new.db(Thread.current[:nobrainer_database])
      env[:options] = env[:options].reverse_merge(:db => db)
    end

    @runner.call(env)
  end
end
