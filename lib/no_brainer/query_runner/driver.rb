class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    # TODO have a logger
    query, options = env.values_at(:query, :options)
    puts query.inspect if ENV['DEBUG']
    query.run(connection, options)
  rescue NoMethodError => err
    raise "NoBrainer is not connected to a RethinkDB instance" unless connection
    raise err
  end

  private
  def connection
    NoBrainer.connection
  end
end
