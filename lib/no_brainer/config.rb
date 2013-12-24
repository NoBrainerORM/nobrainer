module NoBrainer::Config
  class << self
    mattr_accessor :rethinkdb_url, :logger, :warn_on_active_record,
                   :auto_create_databases, :auto_create_tables,
                   :cache_documents, :auto_include_timestamps,
                   :max_reconnection_tries, :include_root_in_json

    def apply_defaults
      self.rethinkdb_url           = guess_rethinkdb_url
      self.logger                  = guess_logger
      self.warn_on_active_record   = true
      self.auto_create_databases   = true
      self.auto_create_tables      = true
      self.cache_documents         = true
      self.auto_include_timestamps = true
      self.max_reconnection_tries  = 10
      self.include_root_in_json    = false
    end

    def reset!
      @configured = false
      apply_defaults
    end

    def configure(&block)
      apply_defaults unless configured?
      block.call(self) if block
      @configured = true

      NoBrainer.disconnect_if_url_changed
    end

    def configured?
      !!@configured
    end

    def guess_rethinkdb_url
      return ENV['RDB_URL'] if ENV['RDB_URL']
      return ENV['RETHINKDB_URL'] if ENV['RETHINKDB_URL']

      if defined?(Rails)
        "rethinkdb://localhost/#{Rails.application.class.parent_name.underscore}_#{Rails.env}"
      end
    end

    def guess_logger
      defined?(Rails) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end
  end
end
