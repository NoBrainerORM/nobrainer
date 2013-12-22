module NoBrainer::Config
  class << self
    mattr_accessor :rethinkdb_url, :logger, :warn_on_active_record,
                   :auto_create_database, :auto_create_tables,
                   :max_reconnection_tries

    def cleanup!
      NoBrainer.disconnect
    end

    def configure(&block)
      self.rethinkdb_url          = guess_rethinkdb_url
      self.logger                 = guess_logger
      self.warn_on_active_record  = true
      self.auto_create_database   = true
      self.auto_create_tables     = true
      self.max_reconnection_tries = 10

      block.call(self) if block
      @configured = true
    end

    def configured?
      !!@configured
    end

    def guess_rethinkdb_url
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
