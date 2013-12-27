class NoBrainer::QueryRunner::Logger < NoBrainer::QueryRunner::Middleware
  def call(env)
    res = @runner.call(env)
    if NoBrainer.logger and NoBrainer.logger.level <= Logger::DEBUG
      msg = env[:query].inspect.gsub("\n", '')
      if msg =~ /Erroneous_Portion_Constructed/
        msg = "r.the_rethinkdb_gem_is_flipping_out_with_Erroneous_Portion_Constructed"
      end
      NoBrainer.logger.debug(msg)
    end
    res
  end
end
