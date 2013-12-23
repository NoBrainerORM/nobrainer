class NoBrainer::QueryRunner::Logging < NoBrainer::QueryRunner::Middleware

  def call(env)
    res = @runner.call(env)
    if NoBrainer.logger and NoBrainer.logger.level <= Logger::DEBUG
      NoBrainer.logger.debug env[:query].inspect.gsub('\n', '')
    end
    res
  end
end
