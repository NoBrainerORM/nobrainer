class NoBrainer::QueryRunner::Logger < NoBrainer::QueryRunner::Middleware
  def call(env)
    start_time = Time.now
    res = @runner.call(env)
    if NoBrainer.logger and NoBrainer.logger.debug?
      duration = Time.now - start_time
      msg = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

      if msg =~ /Erroneous_Portion_Constructed/
        msg = "r.the_rethinkdb_gem_is_flipping_out_with_Erroneous_Portion_Constructed"
      end

      msg = "(#{env[:db_name]}) #{msg}" if env[:db_name]
      msg = "[#{(duration * 1000.0).round(1)}ms] #{msg}"

      if NoBrainer::Config.colorize_logger
        case NoBrainer::Util.rql_type(env[:query])
        when :write      then msg = "\e[1;31m#{msg}\e[0m" # red
        when :read       then msg = "\e[1;32m#{msg}\e[0m" # green
        when :management then msg = "\e[1;33m#{msg}\e[0m" # yellow
        end
      end

      NoBrainer.logger.debug(msg)
    end
    res
  end
end
