class NoBrainer::QueryRunner::Selection < NoBrainer::QueryRunner::Middleware
  def call(env)
    if env[:query].is_a? NoBrainer::Selection
      env[:selection], env[:query] = env[:query], env[:query].query
    end
    @runner.call(env)
  end
end
