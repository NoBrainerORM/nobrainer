class NoBrainer::QueryRunner::Logging < NoBrainer::QueryRunner::Middleware

  def call(env)
    if NoBrainer.logger
      severity = NoBrainer.log_level ? NoBrainer.log_level : Logger::INFO
      NoBrainer.logger.log(severity, env[:query].pp)
    end
    @runner.call(env)
  end

end