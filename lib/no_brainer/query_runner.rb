require 'middleware'

module NoBrainer::QueryRunner
  extend NoBrainer::Autoload

  class Middleware
    def initialize(runner)
      @runner = runner
    end
  end

  autoload :Driver, :DatabaseOnDemand, :TableOnDemand, :WriteError,
           :Connection, :Selection, :Logging, :DatabaseSelector

  class << self
    attr_accessor :stack

    def run(options={}, &block)
      stack.call(:query => yield, :options => options)
    end
  end

  # thread-safe, since require() is ran with a mutex.
  self.stack = ::Middleware::Builder.new do
    use DatabaseSelector
    use Connection
    use WriteError
    use DatabaseOnDemand
    use Logging
    use TableOnDemand
    use Driver
  end
end
