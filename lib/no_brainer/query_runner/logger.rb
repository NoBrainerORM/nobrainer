class NoBrainer::QueryRunner::Logger < NoBrainer::QueryRunner::Middleware
  def call(env)
    start_time = Time.now
    res = @runner.call(env)
    if NoBrainer.logger and NoBrainer.logger.level <= Logger::DEBUG
      stop_time = Time.now
      dt = (stop_time - start_time) * 1000.0
      NoBrainer.logger.debug "#{env[:query].inspect.gsub("\n", '')}  [#{dt} ms]"
    end
    res
  end
end
