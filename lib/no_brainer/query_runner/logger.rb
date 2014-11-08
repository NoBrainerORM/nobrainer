class NoBrainer::QueryRunner::Logger < NoBrainer::QueryRunner::Middleware
  def call(env)
    start_time = Time.now
    @runner.call(env).tap { log_query(env, start_time) }
  rescue Exception => e
    log_query(env, start_time, e)
    raise e
  end

  private

  def log_query(env, start_time, exception=nil)
    return if handle_on_demand_exception?(env, exception)

    not_indexed = env[:criteria] && env[:criteria].where_present? &&
                    !env[:criteria].where_indexed? &&
                    !env[:criteria].model.try(:perf_warnings_disabled)

    level = exception ? Logger::ERROR :
             not_indexed ? Logger::INFO : Logger::DEBUG
    return if NoBrainer.logger.nil? || NoBrainer.logger.level > level

    duration = Time.now - start_time

    msg_duration = (duration * 1000.0).round(1).to_s
    msg_duration = " " * [0, 6 - msg_duration.size].max + msg_duration
    msg_duration = "[#{msg_duration}ms] "

    msg_db = "[#{env[:db_name]}] " if env[:db_name] && env[:db_name].to_s != NoBrainer.connection.parsed_uri[:db]
    msg_query = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

    msg_exception = "#{exception.class} #{exception.message.split("\n").first}" if exception
    msg_exception ||= "perf: filtering without using an index" if not_indexed

    msg_last = nil

    if NoBrainer::Config.colorize_logger
      query_color = case NoBrainer::RQL.type_of(env[:query])
                    when :write      then "\e[1;31m" # red
                    when :read       then "\e[1;32m" # green
                    when :management then "\e[1;33m" # yellow
                    end
      msg_duration = [query_color, msg_duration].join
      msg_db = ["\e[0;34m", msg_db, query_color].join if msg_db
      if msg_exception
        exception_color = "\e[0;31m" if level == Logger::ERROR
        msg_exception = ["\e[0;39m", " -- ", exception_color, msg_exception].compact.join
      end
      msg_last = "\e[0m"
    end

    msg = [msg_duration, msg_db, msg_query, msg_exception, msg_last].join
    NoBrainer.logger.add(level, msg)
  end

  def handle_on_demand_exception?(env, e)
    # pretty gross I must say.
    e && (NoBrainer::QueryRunner::DatabaseOnDemand.new(nil).handle_database_on_demand_exception?(env, e) ||
          NoBrainer::QueryRunner::TableOnDemand.new(nil).handle_table_on_demand_exception?(env, e))
  end
end
