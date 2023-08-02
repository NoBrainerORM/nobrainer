# frozen_string_literal: true

module NoBrainer
  module Profiler
    class SlowQueries < Logger
      def on_query(env)
        return unless NoBrainer::Config.on_slow_query

        query_duration = (env[:duration] * 1000.0).round(1)

        return unless query_duration > NoBrainer::Config.long_query_time

        message = build_message(env)
        NoBrainer::Config.on_slow_query.call(message)
      end

      NoBrainer::Profiler.register(new)
    end
  end
end
