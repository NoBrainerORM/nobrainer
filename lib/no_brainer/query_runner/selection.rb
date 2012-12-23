module NoBrainer::QueryRunner::Selection
  def run(env)
    if env[:query].is_a? NoBrainer::Selection
      env[:selection], env[:query] = env[:query], env[:query].query
    end
    super(env)
  end
end
