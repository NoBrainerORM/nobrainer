class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    if NoBrainer::Config.durability.to_s != 'hard'
      env[:options] = env[:options].reverse_merge(:durability => NoBrainer::Config.durability)
    end

    env[:query].run(NoBrainer.connection, env[:options])
  rescue NoMethodError => e
    raise "NoBrainer is not connected to a RethinkDB instance" unless NoBrainer.connection
    raise e
  end
end
