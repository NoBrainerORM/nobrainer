module NoBrainer::Config
  class << self
    mattr_accessor :rethinkdb_url, :logger, :warn_on_active_record,
                   :auto_create_databases, :auto_create_tables,
                   :cache_documents, :auto_include_timestamps,
                   :max_reconnection_tries, :include_root_in_json,
                   :durability, :colorize_logger

    def apply_defaults
      self.rethinkdb_url           = default_rethinkdb_url
      self.logger                  = default_logger
      self.warn_on_active_record   = true
      self.auto_create_databases   = true
      self.auto_create_tables      = true
      self.cache_documents         = true
      self.auto_include_timestamps = true
      self.max_reconnection_tries  = 10
      self.include_root_in_json    = false
      self.durability              = default_durability
      self.colorize_logger         = true
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

    def default_rethinkdb_url
      return ENV['RETHINKDB_URL'] if ENV['RETHINKDB_URL']

      if defined?(Rails)
        host = ENV['RETHINKDB_HOST'] || 'localhost'
        port = ENV['RETHINKDB_PORT']
        auth = ENV['RETHINKDB_AUTH']
        db_name = "#{Rails.application.class.parent_name.underscore}_#{Rails.env}"

        "rethinkdb://#{":#{auth}@" if auth}#{host}#{":#{port}" if port}/#{db_name}"
      end
    end

    def default_logger
      defined?(Rails) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end

    def default_durability
      (defined?(Rails) && (Rails.env.test? || Rails.env.development?)) ? :soft : :hard
    end
  end
end
