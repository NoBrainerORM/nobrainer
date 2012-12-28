class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    # TODO have a logger
    puts env[:query].inspect if ENV['DEBUG']
    NoBrainer.connection.run(env[:query], env[:options])
  rescue NoMethodError => e
    raise "NoBrainer is not connected to a RethinkDB instance" unless NoBrainer.connection
    raise e
  end
end
