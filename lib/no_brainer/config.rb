require 'logger'

module NoBrainer::Config
  class << self
    mattr_accessor :app_name, :environment, :rethinkdb_url,
                   :logger, :warn_on_active_record,
                   :auto_create_databases, :auto_create_tables,
                   :max_retries_on_connection_failure, :durability,
                   :user_timezone, :db_timezone, :colorize_logger,
                   :distributed_lock_class, :per_thread_connection

    def apply_defaults
      self.app_name                          = default_app_name
      self.environment                       = default_environment
      self.rethinkdb_url                     = default_rethinkdb_url
      self.logger                            = default_logger
      self.warn_on_active_record             = true
      self.auto_create_databases             = true
      self.auto_create_tables                = true
      self.max_retries_on_connection_failure = default_max_retries_on_connection_failure
      self.durability                        = default_durability
      self.user_timezone                     = :local
      self.db_timezone                       = :utc
      self.colorize_logger                   = true
      self.distributed_lock_class            = nil
      self.per_thread_connection             = false
    end

    def max_reconnection_tries=(value)
      STDERR.puts "[NoBrainer] config.max_reconnection_tries is deprecated and will be removed"
      STDERR.puts "[NoBrainer] use config.max_retries_on_connection_failure instead."
      self.max_retries_on_connection_failure = value
    end

    def reset!
      @configured = false
      apply_defaults
    end

    def configure(&block)
      apply_defaults unless configured?
      block.call(self) if block
      assert_valid_options!
      @configured = true

      NoBrainer::ConnectionManager.disconnect_if_url_changed
    end

    def configured?
      !!@configured
    end

    def assert_valid_options!
      assert_array_in :durability,    [:hard, :soft]
      assert_array_in :user_timezone, [:unchanged, :utc, :local]
      assert_array_in :db_timezone,   [:unchanged, :utc, :local]
    end

    def assert_array_in(name, values)
      unless __send__(name).in?(values)
        raise ArgumentError.new("Unknown configuration for #{name}: #{__send__(name)}. Valid values are: #{values.inspect}")
      end
    end

    def default_app_name
      defined?(Rails) ? Rails.application.class.parent_name.underscore.presence : nil rescue nil
    end

    def default_environment
      return Rails.env if defined?(Rails.env)
      ENV['RUBY_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || :production
    end

    def default_rethinkdb_url
      db = ENV['RETHINKDB_DB'] || ENV['RDB_DB']
      db ||= "#{self.app_name}_#{self.environment}" if self.app_name && self.environment
      host = ENV['RETHINKDB_HOST'] || ENV['RDB_HOST'] || 'localhost'
      port = ENV['RETHINKDB_PORT'] || ENV['RDB_PORT']
      auth = ENV['RETHINKDB_AUTH'] || ENV['RDB_AUTH']
      url = ENV['RETHINKDB_URL'] || ENV['RDB_URL']
      url ||= "rethinkdb://#{":#{auth}@" if auth}#{host}#{":#{port}" if port}/#{db}" if db
      url
    end

    def default_logger
      defined?(Rails.logger) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end

    def default_durability
      dev_mode? ? :soft : :hard
    end

    def default_max_retries_on_connection_failure
      dev_mode? ? 1 : 15
    end

    def dev_mode?
      self.environment.to_sym.in?([:development, :test])
    end
  end
end
