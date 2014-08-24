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

    msg_duration = (duration * 1000.0).round(1).to_s
    msg_duration = " " * [0, 5 - msg_duration.size].max + msg_duration
    msg_duration = "[#{msg_duration}ms] "

    msg_db = "[#{env[:db_name]}] " if env[:db_name] && env[:db_name].to_s != NoBrainer.connection.parsed_uri[:db]
    msg_query = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')
    msg_exception = " #{exception.class} #{exception.message.split("\n").first}" if exception
    msg_last = nil

    if NoBrainer::Config.colorize_logger
      query_color = case NoBrainer::RQL.type_of(env[:query])
                    when :write      then "\e[1;31m" # red
                    when :read       then "\e[1;32m" # green
                    when :management then "\e[1;33m" # yellow
                    end
      msg_duration = [query_color, msg_duration].join
      msg_db = ["\e[0;34m", msg_db, query_color].join if msg_db
      msg_exception = ["\e[0;31m", msg_exception].join if msg_exception
      msg_last = "\e[0m"
    end

    msg = [msg_duration, msg_db, msg_query, msg_exception, msg_last].join
    NoBrainer.logger.debug(msg)
  end
end
