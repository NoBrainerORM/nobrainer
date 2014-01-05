class NoBrainer::QueryRunner::Driver < NoBrainer::QueryRunner::Middleware
  def call(env)
    env[:query].run(NoBrainer.connection.raw, env[:options])
  end
end
