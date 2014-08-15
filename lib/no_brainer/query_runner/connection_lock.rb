class NoBrainer::QueryRunner::ConnectionLock < NoBrainer::QueryRunner::Middleware
  @@lock = Mutex.new

  def call(env)
    @@lock.synchronize { @runner.call(env) }
  end
end
