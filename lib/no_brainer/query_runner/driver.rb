class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    options = env[:options]
    options = options.merge(:db => RethinkDB::RQL.new.db(options[:db])) if options[:db]
    env[:query].run(NoBrainer.connection.raw, options)
  end
end
