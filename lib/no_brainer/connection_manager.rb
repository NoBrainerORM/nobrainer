module NoBrainer::ConnectionManager
  extend self

  @lock = Mutex.new

  def synchronize(&block)
    if NoBrainer::Config.per_thread_connection
      block.call
    else
      @lock.synchronize { block.call }
    end
  end

  def get_new_connection
    url = NoBrainer::Config.rethinkdb_url
    raise "Please specify a database connection to RethinkDB" unless url
    NoBrainer::Connection.new(url)
  end

  def current_connection
    if NoBrainer::Config.per_thread_connection
      Thread.current[:nobrainer_connection]
    else
      @connection
    end
  end

  def current_connection=(value)
    if NoBrainer::Config.per_thread_connection
      Thread.current[:nobrainer_connection] = value
    else
      @connection = value
    end
  end

  def connection
    c = self.current_connection
    return c if c

    synchronize do
      self.current_connection ||= get_new_connection
    end
  end

  def _disconnect
    self.current_connection.try(:close, :noreply_wait => false) rescue nil
    self.current_connection = nil
  end

  def disconnect
    synchronize { _disconnect }
  end

  def disconnect_if_url_changed
    synchronize do
      c = current_connection
      _disconnect if c && c.uri != NoBrainer::Config.rethinkdb_url
    end
  end
end
