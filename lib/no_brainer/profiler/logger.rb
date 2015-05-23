class NoBrainer::Profiler::Logger
  def on_query(env)
    level = env[:exception] ? Logger::ERROR : Logger::DEBUG
    return if NoBrainer.logger.nil? || NoBrainer.logger.level > level

    msg_duration = (env[:duration] * 1000.0).round(1).to_s
    msg_duration = " " * [0, 6 - msg_duration.size].max + msg_duration
    msg_duration = "[#{msg_duration}ms] "

    env[:query_type] = NoBrainer::RQL.type_of(env[:query])
    env[:custom_db_name] = env[:db_name] if env[:db_name].to_s != NoBrainer.connection.parsed_uri[:db]

    msg_db = "[#{env[:custom_db_name]}] " if env[:custom_db_name]
    msg_query = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

    msg_exception = "#{env[:exception].class} #{env[:exception].message.split("\n").first}" if env[:exception]

    msg_last = nil

    if NoBrainer::Config.colorize_logger
      query_color = case env[:query_type]
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

  NoBrainer::Profiler.register(self.new)
end
