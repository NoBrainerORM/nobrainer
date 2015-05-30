class NoBrainer::QueryRunner::Profiler < NoBrainer::QueryRunner::Middleware
  def call(env)
    profiler_start(env)
    @runner.call(env).tap { profiler_end(env) }
  rescue Exception => e
    profiler_end(env, e)
    raise e
  end

  private

  def profiler_start(env)
    env[:start_time] = Time.now
  end

  def profiler_end(env, exception=nil)
    return if handle_on_demand_exception?(env, exception)

    env[:end_time] = Time.now
    env[:duration] = env[:end_time] - env[:start_time]
    env[:exception] = exception

    env[:model] = env[:criteria] && env[:criteria].model
    env[:query_type] = NoBrainer::RQL.type_of(env[:query])

    NoBrainer::Profiler.registered_profilers.each do |profiler|
      begin
        profiler.on_query(env)
      rescue Exception => e
        STDERR.puts "[NoBrainer] Profiling error: #{e.class} #{e.message}"
      end
    end
  end

  def handle_on_demand_exception?(env, e)
    # pretty gross I must say.
    e && (NoBrainer::QueryRunner::DatabaseOnDemand.new(nil).handle_database_on_demand_exception?(env, e) ||
          NoBrainer::QueryRunner::TableOnDemand.new(nil).handle_table_on_demand_exception?(env, e))
  end
end

