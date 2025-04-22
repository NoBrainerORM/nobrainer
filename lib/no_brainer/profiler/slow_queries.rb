# frozen_string_literal: true

module NoBrainer
  module Profiler
    class SlowQueries < Logger
      def on_query(env)
        return unless NoBrainer::Config.on_slow_query
        puts " ->> slow_query?(env): #{slow_query?(env).inspect}"
        return unless slow_query?(env)

        NoBrainer::Config.on_slow_query.call(build_message(env))
      end

      private

      def query_duration(env)
        (env[:duration] * 1000.0).round(1)
      end

      def slow_query?(env)
        query_duration(env) > NoBrainer::Config.long_query_time
      end

      NoBrainer::Profiler.register(new)
    end
  end
end
