require 'logger'

module NoBrainer::Config
  class << self
    mattr_accessor :rethinkdb_url, :logger, :warn_on_active_record,
                   :auto_create_databases, :auto_create_tables,
                   :max_reconnection_tries, :durability,
                   :user_timezone, :db_timezone, :colorize_logger,
                   :distributed_lock_class

    def apply_defaults
      self.rethinkdb_url           = default_rethinkdb_url
      self.logger                  = default_logger
      self.warn_on_active_record   = true
      self.auto_create_databases   = true
      self.auto_create_tables      = true
      self.max_reconnection_tries  = 10
      self.durability              = default_durability
      self.user_timezone           = :local
      self.db_timezone             = :utc
      self.colorize_logger         = true
      self.distributed_lock_class  = nil
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

      NoBrainer.disconnect_if_url_changed
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

    def default_rethinkdb_url
      db = ENV['RETHINKDB_DB'] || ENV['RDB_DB']
      db ||= "#{Rails.application.class.parent_name.underscore}_#{Rails.env}" rescue nil
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
      (defined?(Rails.env) && (Rails.env.test? || Rails.env.development?)) ? :soft : :hard
    end
  end
end
