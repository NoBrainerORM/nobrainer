# frozen_string_literal: true

module NoBrainer
  module Profiler
    class Logger
      def on_query(env)
        level = ::Logger::ERROR if env[:exception]
        level ||= not_indexed(env) ? ::Logger::INFO : ::Logger::DEBUG
        return if NoBrainer.logger.level > level

        NoBrainer.logger.add(level, build_message(env))
      end

      private

      def build_message(env)
        msg_duration = (env[:duration] * 1000.0).round(1).to_s
        msg_duration = (' ' * [0, 6 - msg_duration.size].max) + msg_duration
        msg_duration = "[#{msg_duration}ms] "

        env[:query_type] = NoBrainer::RQL.type_of(env[:query])

        msg_db = "[#{env[:options][:db]}] " if env[:options][:db]
        msg_query = env[:query].inspect.gsub(/\n/, '').gsub(/ +/, ' ')

        msg_exception = "#{env[:exception].class} #{env[:exception].message.split("\n").first}" if env[:exception]
        msg_exception ||= 'perf: filtering without using an index' if not_indexed(env)

        msg_last = nil

        if NoBrainer::Config.colorize_logger
          msg_duration = [query_color(env[:query_type]), msg_duration].join
          msg_db = ["\e[0;34m", msg_db, query_color(env[:query_type])].join if msg_db
          if msg_exception
            exception_color = "\e[0;31m" if level == Logger::ERROR
            msg_exception = ["\e[0;39m", ' -- ', exception_color, msg_exception].compact.join
          end
          msg_last = "\e[0m"
        end

        [msg_duration, msg_db, msg_query, msg_exception, msg_last].join
      end

      def not_indexed(env)
        env[:criteria] &&
          env[:criteria].where_present? &&
          !env[:criteria].where_indexed? &&
          !env[:criteria].model.try(:perf_warnings_disabled)
      end

      def query_color(query_type)
        {
          write: "\e[1;31m", # red
          read: "\e[1;32m", # green
          management: "\e[1;33m" # yellow
        }[query_type]
      end

      NoBrainer::Profiler.register(new)
    end
  end
end
