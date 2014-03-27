class NoBrainer::QueryRunner::Logger < NoBrainer::QueryRunner::Middleware
  def call(env)
    start_time = Time.now
    @runner.call(env).tap { log_query(env, start_time) }
  rescue Exception => e
    log_query(env, start_time, e) rescue nil
    raise e
  end

  private

  def log_query(env, start_time, exception=nil)
    return unless NoBrainer.logger.debug?

    duration = Time.now - start_time
    msg = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

    msg = "(#{env[:db_name]}) #{msg}" if env[:db_name]
    msg = "[#{(duration * 1000.0).round(1)}ms] #{msg}"

    if NoBrainer::Config.colorize_logger
      if exception
        msg = "#{msg} \e[0;31m#{exception.class} #{exception.message.split("\n").first}\e[0m"
      else
        case NoBrainer::Util.rql_type(env[:query])
        when :write      then msg = "\e[1;31m#{msg}\e[0m" # red
        when :read       then msg = "\e[1;32m#{msg}\e[0m" # green
        when :management then msg = "\e[1;33m#{msg}\e[0m" # yellow
        end
      end
    end

    NoBrainer.logger.debug(msg)
  end
end
