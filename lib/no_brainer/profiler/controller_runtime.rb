# Rails specific. TODO Test
module NoBrainer::Profiler::ControllerRuntime
  extend ActiveSupport::Concern

  class Profiler
    attr_accessor :write_duration, :read_duration, :other_duration
    def initialize
      @write_duration = @read_duration = @other_duration = 0.0
    end

    def total_duration
      read_duration + write_duration + other_duration
    end

    def add_query(env)
      case env[:query_type]
      when :write      then @write_duration += env[:duration]
      when :read       then @read_duration  += env[:duration]
      else                  @other_duration += env[:duration]
      end
    end

    def self.spawn_controller_profiler
      Thread.current[:nobrainer_controller_profiler] = new
    end

    def self.cleanup_controller_profiler
      Thread.current[:nobrainer_controller_profiler] = nil
    end

    def self.current
      Thread.current[:nobrainer_controller_profiler]
    end

    def self.on_query(env)
      current.try(:add_query, env)
    end

    NoBrainer::Profiler.register(self)
  end

  def process_action(action, *args)
    Profiler.spawn_controller_profiler
    super
  ensure
    Profiler.cleanup_controller_profiler
  end

  def cleanup_view_runtime
    return super unless Profiler.current

    time_spent_in_db_before_views = Profiler.current.total_duration
    runtime = super
    time_spent_in_db_after_views = Profiler.current.total_duration

    time_spent_in_db_during_views = (time_spent_in_db_after_views - time_spent_in_db_before_views) * 1000
    runtime - time_spent_in_db_during_views
  end

  def append_info_to_payload(payload)
    super
    payload[:nobrainer_profiler] = Profiler.current
  end

  module ClassMethods # :nodoc:
    def log_process_action(payload)
      messages, profiler = super, payload[:nobrainer_profiler]
      if profiler && !profiler.total_duration.zero?
        msg = []
        msg << "%.1fms (write)" % (profiler.write_duration * 1000) unless profiler.write_duration.zero?
        msg << "%.1fms (read)"  % (profiler.read_duration  * 1000) unless profiler.read_duration.zero?
        msg << "%.1fms (other)" % (profiler.other_duration * 1000) unless profiler.other_duration.zero?
        messages << "NoBrainer: #{msg.join(", ")}"
      end
      messages
    end
  end
end
