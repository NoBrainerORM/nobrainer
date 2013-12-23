class NoBrainer::QueryRunner::Logging < NoBrainer::QueryRunner::Middleware

  def call(env)
    if NoBrainer.logger
      NoBrainer.logger.debug env[:query].pp
    end
    @runner.call(env)
  end

end