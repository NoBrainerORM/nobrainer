require 'middleware'
require 'rethinkdb'

module NoBrainer::QueryRunner
  extend NoBrainer::Autoload

  class Middleware
    def initialize(runner)
      @runner = runner
    end
  end

  autoload :EMDriver, :Driver, :DatabaseOnDemand, :TableOnDemand, :WriteError,
           :Reconnect, :RunOptions, :Profiler, :MissingIndex, :ConnectionLock

  class << self
    def run(*args, &block)
      options = args.extract_options!
      raise ArgumentError unless args.size == 1 || block
      query = args.first || block.call(RethinkDB::RQL.new)
      stack.call(:query => query, :options => options)
    end

    def stack
      case NoBrainer::Config.driver
      when :regular then normal_stack
      when :em      then em_stack
      end
    end

    def normal_stack
      @normal_stack ||= ::Middleware::Builder.new do
        use RunOptions
        use MissingIndex
        use DatabaseOnDemand
        use TableOnDemand
        use Profiler
        use WriteError
        use ConnectionLock
        use Reconnect
        use Driver
      end
    end

    def em_stack
      @em_stack ||= ::Middleware::Builder.new do
        use RunOptions
        use MissingIndex
        use DatabaseOnDemand
        use TableOnDemand
        use Profiler
        use WriteError
        use Reconnect
        use EMDriver
      end
    end
  end
end
