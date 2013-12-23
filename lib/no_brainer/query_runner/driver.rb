class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    env[:query].run(NoBrainer.connection, env[:options])
  rescue NoMethodError => e
    raise "NoBrainer is not connected to a RethinkDB instance" unless NoBrainer.connection
    raise e
  end
end
