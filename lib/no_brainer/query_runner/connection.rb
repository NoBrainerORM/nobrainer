module NoBrainer::QueryRunner::Connection
  def run(env)
    NoBrainer.connection.run(env[:query], env[:options])
  end
end
