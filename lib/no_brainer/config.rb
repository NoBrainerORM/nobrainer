require 'logger'

module NoBrainer::Config
  class << self
    mattr_accessor :rethinkdb_url, :logger, :warn_on_active_record,
                   :auto_create_databases, :auto_create_tables,
                   :max_reconnection_tries, :durability, :colorize_logger

    def apply_defaults
      self.rethinkdb_url           = default_rethinkdb_url
      self.logger                  = default_logger
      self.warn_on_active_record   = true
      self.auto_create_databases   = true
      self.auto_create_tables      = true
      self.max_reconnection_tries  = 10
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
      return url_from_env if url_from_env

      url = 'rethinkdb://'
      url += ":#{auth}@" if auth
      url += host
      url += ":#{port}" if port
      url += "/#{database}" if database

      url
    end

    def default_logger
      if defined? Rails
        Rails.logger
      else
        Logger.new(STDERR).tap do |logger|
          logger.level = Logger::WARN
        end
      end
    end

    def default_durability
      if defined? Rails && !Rails.env.production?
        :soft
      else
        :hard
      end
    end

    private

    def url_from_env
      ENV['RETHINKDB_URL'] || ENV['RDB_URL']
    end

    def database
      database_name_from_env || database_name_from_application_name
    end

    def database_name_from_env
      ENV['RETHINKDB_DB'] || ENV['RDB_DB']
    end

    def database_name_from_application_name
      if defined?(Rails)
        "#{Rails.application.class.parent_name.underscore}_#{Rails.env}"
      end
    end

    def host
      ENV['RETHINKDB_HOST'] || ENV['RDB_HOST'] || 'localhost'
    end

    def port
      ENV['RETHINKDB_PORT'] || ENV['RDB_PORT']
    end

    def auth
      ENV['RETHINKDB_AUTH'] || ENV['RDB_AUTH']
    end
  end
end
