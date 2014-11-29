require 'logger'

module NoBrainer::Config
  SETTINGS = {
    :app_name               => { :default => ->{ default_app_name } },
    :environment            => { :default => ->{ default_environment } },
    :rethinkdb_url          => { :default => ->{ default_rethinkdb_url } },
    :logger                 => { :default => ->{ default_logger } },
    :warn_on_active_record  => { :default => ->{ true }, :valid_values => [true, false] },
    :auto_create_databases  => { :default => ->{ true }, :valid_values => [true, false] },
    :auto_create_tables     => { :default => ->{ true }, :valid_values => [true, false] },
    :max_retries_on_connection_failure => { :default => ->{ default_max_retries_on_connection_failure } },
    :durability             => { :default => ->{ default_durability }, :valid_values => [:hard, :soft] },
    :user_timezone          => { :default => ->{ :local }, :valid_values => [:unchanged, :utc, :local] },
    :db_timezone            => { :default => ->{ :utc }, :valid_values => [:unchanged, :utc, :local] },
    :colorize_logger        => { :default => ->{ true }, :valid_values => [true, false] },
    :distributed_lock_class => { :default => ->{ nil } },
    :per_thread_connection  => { :default => ->{ false }, :valid_values => [true, false] },
    :machine_id             => { :default => ->{ default_machine_id } },
    :geo_options            => { :default => ->{ {:geo_system => 'WGS84', :unit => 'm'} } },
  }

  class << self
    attr_accessor(*SETTINGS.keys)

    def max_reconnection_tries=(value)
      STDERR.puts "[NoBrainer] config.max_reconnection_tries is deprecated and will be removed"
      STDERR.puts "[NoBrainer] use config.max_retries_on_connection_failure instead."
      self.max_retries_on_connection_failure = value
    end

    def apply_defaults
      @applied_defaults_for = SETTINGS.keys.reject { |k| instance_variable_defined?("@#{k}") }
      @applied_defaults_for.each { |k| __send__("#{k}=", SETTINGS[k][:default].call) }
    end

    def geo_options=(value)
      @geo_options = value.try(:symbolize_keys)
    end

    def assert_valid_options
      SETTINGS.each { |k,v| assert_array_in(k, v[:valid_values]) if v[:valid_values] }
    end

    def reset!
      instance_variables.each { |ivar| remove_instance_variable(ivar) }
    end

    def configure(&block)
      @applied_defaults_for.to_a.each { |k| remove_instance_variable("@#{k}") }
      block.call(self) if block
      apply_defaults
      assert_valid_options
      @configured = true

      NoBrainer::ConnectionManager.disconnect_if_url_changed
    end

    def configured?
      !!@configured
    end

    def assert_array_in(name, values)
      unless __send__(name).in?(values)
        raise ArgumentError.new("Unknown configuration for #{name}: #{__send__(name)}. Valid values are: #{values.inspect}")
      end
    end

    def dev_mode?
      self.environment.to_s.in? %w(development test)
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

    def default_machine_id
      require 'socket'
      require 'digest/md5'

      return ENV['MACHINE_ID'] if ENV['MACHINE_ID']

      host = Socket.gethostname
      if host.in? %w(127.0.0.1 localhost)
        raise "Please configure NoBrainer::Config.machine_id due to lack of appropriate hostname (Socket.gethostname = #{host})"
      end

      Digest::MD5.digest(host).unpack("N")[0] & NoBrainer::Document::PrimaryKey::Generator::MACHINE_ID_MASK
    end

    def machine_id=(machine_id)
      machine_id = case machine_id
        when Integer    then machine_id
        when /^[0-9]+$/ then machine_id.to_i
        else raise "Invalid machine_id"
      end
      max_id = NoBrainer::Document::PrimaryKey::Generator::MACHINE_ID_MASK
      raise "Invalid machine_id (must be between 0 and #{max_id})" unless machine_id.in?(0..max_id)
      @machine_id = machine_id
    end
  end
end
