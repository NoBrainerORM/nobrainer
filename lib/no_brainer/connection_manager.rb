module NoBrainer::ConnectionManager
  extend self

  @lock = Mutex.new

  def synchronize(&block)
    @lock.synchronize { block.call }
  end

  def warn_for_other_orms
    if defined?(ActiveRecord) && NoBrainer::Config.warn_on_active_record
      STDERR.puts "[NoBrainer] ActiveRecord is loaded which is probably not what you want."
      STDERR.puts "[NoBrainer] Follow the instructions on http://nobrainer.io/docs/configuration/#removing_activerecord"
      STDERR.puts "[NoBrainer] Configure NoBrainer with 'config.warn_on_active_record = false' to disable with warning."
    end

    if defined?(Mongoid)
      STDERR.puts "[NoBrainer] WARNING: Mongoid is loaded, and we conflict on the symbol decorations"
      STDERR.puts "[NoBrainer] They are used in queries such as Model.where(:tags.in => ['fun', 'stuff'])"
      STDERR.puts "[NoBrainer] This is a problem!"
    end
  end

  def get_new_connection
    # We don't want to warn on "rails g nobrainer:install", but because it's
    # hard to check when the generator is running because of spring as it wipes
    # ARGV. So we check for other ORMs during the connection instantiation.
    warn_for_other_orms

    NoBrainer::Connection.new(get_next_url)
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

  def get_next_url
    @urls ||= NoBrainer::Config.rethinkdb_urls.shuffle
    @cycle_index = (@cycle_index || 0) + 1
    @urls[@cycle_index % @urls.size] # not using .cycle due to threading issues
  end

  def connection
    c = self.current_connection
    return c if c

    synchronize do
      self.current_connection ||= get_new_connection
    end
  end

  def _disconnect
    c, self.current_connection = self.current_connection, nil
    c.try(:close, :noreply_wait => false) rescue nil
  end

  def disconnect
    return unless self.current_connection
    synchronize { _disconnect }
  end

  def notify_url_change
    synchronize do
      @urls = nil
      c = current_connection
      _disconnect if c && !NoBrainer::Config.rethinkdb_urls.include?(c.orig_uri)
    end
  end
end
