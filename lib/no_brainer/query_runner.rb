require 'middleware'
require 'rethinkdb'

module NoBrainer::QueryRunner
  extend NoBrainer::Autoload

  class Middleware
    def initialize(runner)
      @runner = runner
    end
  end

  autoload :Driver, :DatabaseOnDemand, :TableOnDemand, :WriteError,
           :Connection, :Selection, :DatabaseSelector, :Logger

  class << self
    attr_accessor :stack

    def run(*args, &block)
      options = args.extract_options!
      raise ArgumentError unless args.size == 1 || block
      query = args.first || block.call(RethinkDB::RQL.new)
      stack.call(:query => query, :options => options)
    end
  end

  # thread-safe, since require() is ran with a mutex.
  self.stack = ::Middleware::Builder.new do
    use DatabaseSelector
    use Connection
    use WriteError
    use DatabaseOnDemand
    use TableOnDemand
    use Logger
    use Driver
  end
end
