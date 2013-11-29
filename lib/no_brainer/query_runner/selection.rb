class NoBrainer::QueryRunner::Selection < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(self.class.normalize_query_and_selection(env))
  end

  def self.normalize_query_and_selection(env)
    query, selection = env.values_at(:query, :selection)
    if query.is_a? NoBrainer::Selection
      env[:selection], env[:query] = query, query.query
    end
    env
  end
end
