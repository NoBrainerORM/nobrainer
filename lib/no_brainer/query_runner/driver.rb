module NoBrainer::QueryRunner::Driver
  def run(env)
    # TODO have a logger
    puts env[:query].inspect if ENV['DEBUG']
    NoBrainer.connection.run(env[:query], env[:options])
  rescue NoMethodError => e
    raise "NoBrainer is not connected to a RethinkDB instance" unless NoBrainer.connection
    raise e
  end
end
