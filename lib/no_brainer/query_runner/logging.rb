class NoBrainer::QueryRunner::Logging < NoBrainer::QueryRunner::Middleware

  def call(env)
    if NoBrainer.config.logger
      severity = NoBrainer.config.log_level ? NoBrainer.config.log_level : Logger::INFO
      NoBrainer.config.logger.log(severity, "#{NoBrainer.config.log_prefix} #{env[:query].pp}")
    end
    @runner.call(env)
  end

end