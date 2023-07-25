# frozen_string_literal: true

module NoBrainer
  module Profiler
    class SlowQueries < Logger
      def on_query(env)
        return unless NoBrainer::Config.log_slow_queries

        query_duration = (env[:duration] * 1000.0).round(1)

        return unless query_duration > NoBrainer::Config.long_query_time

        File.write(
          NoBrainer::Config.slow_query_log_file,
          build_message(env),
          mode: 'a'
        )
      end

      NoBrainer::Profiler.register(new)
    end
  end
end
