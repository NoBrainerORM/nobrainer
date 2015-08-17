require 'eventmachine'
require 'fiber'

class NoBrainer::QueryRunner::EMDriver < NoBrainer::QueryRunner::Middleware
  def call(env)
    options = env[:options]
    options = options.merge(:db => RethinkDB::RQL.new.db(options[:db])) if options[:db]

    handler = ResponseHandler.new
    query_handler = env[:query].em_run(NoBrainer.connection.raw, handler, options)
    handler.on_dispatch(query_handler)
    handler.value
  end

  def self.sync(&block)
    # Similar to em-synchrony's sync.
    f = Fiber.current
    block.call(proc do |val|
      if f == Fiber.current
        return val
      else
        f.resume(val)
      end
    end)
    Fiber.yield
  end

  class ResponseHandler < RethinkDB::Handler
    def initialize
      @ready = EventMachine::DefaultDeferrable.new
    end

    def close_query_handle
      @query_handle.close
    end

    def on_dispatch(caller)
      @query_handle = caller
    end

    def on_open(caller)
      @has_data = true
    end

    def on_close(caller)
      return if @has_atom
      return on_error(RethinkDB::RqlRuntimeError.new("NoBrainer EM driver: No data received"), caller) unless @has_data
      @queue ? push(:close) : set_atom([])
    end

    def on_error(err, caller)
      @error = err
      push(err)
    end

    def on_atom(val, caller)
      set_atom(val)
    end

    def on_array(arr, caller)
      set_atom(arr)
    end

    def on_stream_val(val, caller)
      push([val])
    end

    def on_unhandled_change(val, caller)
      push([val])
    end

    def push(v)
      raise "internal error: unexpected stream" if @has_atom
      @queue ||= EventMachine::Queue.new
      @queue.push(v)
      response_ready!
    end

    def set_atom(v)
      raise "internal error: unexpected atom" if @queue
      @has_atom = true
      @value = v
      response_ready!
    end

    def response_ready!
      @ready.succeed(nil) if @ready
    end

    def wait_for_response
      NoBrainer::QueryRunner::EMDriver.sync { |w| @ready.callback(&w) } if @ready
      @ready = nil
    end

    def value
      wait_for_response
      raise @error if @error
      @has_atom ? @value : Cursor.new(self, @queue)
    end

    class Cursor
      include Enumerable
      def initialize(handler, queue)
        @handler = handler
        @queue = queue
      end

      def close
        @handler.close_query_handle
      end

      def each(&block)
        return enum_for(:each) unless block

        raise "Can only iterate over a cursor once." if @iterated
        @iterated = true

        loop do
          case result = NoBrainer::QueryRunner::EMDriver.sync { |w| @queue.pop(&w) }
          when :close then return self
          when Exception then raise result
          else result.each { |v| block.call(v) }
          end
        end
      end
    end
  end
end
