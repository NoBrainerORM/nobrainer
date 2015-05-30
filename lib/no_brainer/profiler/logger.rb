class NoBrainer::Profiler::Logger
  def on_query(env)
    not_indexed = env[:criteria] && env[:criteria].where_present? &&
                    !env[:criteria].where_indexed? &&
                    !env[:criteria].model.try(:perf_warnings_disabled)

    level = env[:exception] ? Logger::ERROR :
             not_indexed ? Logger::INFO : Logger::DEBUG
    return if NoBrainer.logger.nil? || NoBrainer.logger.level > level

    msg_duration = (env[:duration] * 1000.0).round(1).to_s
    msg_duration = " " * [0, 6 - msg_duration.size].max + msg_duration
    msg_duration = "[#{msg_duration}ms] "

    env[:query_type] = NoBrainer::RQL.type_of(env[:query])

    msg_db = "[#{env[:options][:db]}] " if env[:options][:db]
    msg_query = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

    msg_exception = "#{env[:exception].class} #{env[:exception].message.split("\n").first}" if env[:exception]
    msg_exception ||= "perf: filtering without using an index" if not_indexed

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
