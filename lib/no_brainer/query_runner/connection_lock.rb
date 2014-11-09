class NoBrainer::QueryRunner::ConnectionLock < NoBrainer::QueryRunner::Middleware
  @@lock = Mutex.new

  def call(env)
    if NoBrainer::Config.per_thread_connection
      @runner.call(env)
    else
      @@lock.synchronize { @runner.call(env) }
    end
  end
end
