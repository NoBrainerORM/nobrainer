module NoBrainer::Streams
  extend ActiveSupport::Concern

  included do
    on_unsubscribe :stop_all_streams
  end

  private

  def stream_from(query, options = {}, callback = nil)
    callback ||= -> (changes) do
      transmit changes, via: "streamed from #{query.inspect}"
    end

    # defer_subscription_confirmation!
    connection = NoBrainer::Streams::streams_connection
    cursor = query.to_rql.changes(options).async_run(connection, ConcurrentAsyncHandler, &callback)
    cursors << cursor
  end

  def stop_all_streams
    cursors.each do |cursor|
      begin
        logger.info "Closing cursor: #{cursor.inspect}"
        cursor.close
      rescue => e
        logger.error "Could not close cursor: #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end
  end
  
  def cursors
    @_cursors ||= []
  end

  def self.streams_connection
    @@streams_connection ||= NoBrainer::ConnectionManager.get_new_connection.raw
  end

  class ConcurrentAsyncHandler < RethinkDB::AsyncHandler
    def run(&action)
      options[:query_handle_class] = AsyncQueryHandler
      yield
    end

    def handler
      callback
    end

    class AsyncQueryHandler < RethinkDB::QueryHandle
      def guarded_async_run(&b)
        Concurrent.global_io_executor.post(&b)
      end
    end
  end
end
