module NoBrainer::Profiler
  class << self
    attr_accessor :registered_profilers

    def register(profiler)
      self.registered_profilers << profiler
    end
  end

  self.registered_profilers = []
end
