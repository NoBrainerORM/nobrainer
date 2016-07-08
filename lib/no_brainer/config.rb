require 'logger'

module NoBrainer::Config
  SETTINGS = {
    :app_name               => { :default => ->{ default_app_name } },
    :environment            => { :default => ->{ default_environment } },
    :rethinkdb_urls         => { :default => ->{ [default_rethinkdb_url] } },
    :ssl_options            => { :default => ->{ nil } },
    :driver                 => { :default => ->{ :regular }, :valid_values => [:regular, :em] },
    :logger                 => { :default => ->{ default_logger } },
    :colorize_logger        => { :default => ->{ true }, :valid_values => [true, false] },
    :warn_on_active_record  => { :default => ->{ true }, :valid_values => [true, false] },
    :durability             => { :default => ->{ nil } }, # legacy
    :table_options          => { :default => ->{ {:shards => 1, :replicas => 1, :write_acks => :majority} },
                                 :valid_keys => [:shards, :replicas, :primary_replica_tag, :write_acks, :durability] },
    :run_options            => { :default => ->{ {:durability => default_durability} } },
    :max_string_length      => { :default => ->{ 255 } },
    :user_timezone          => { :default => ->{ :local }, :valid_values => [:unchanged, :utc, :local] },
    :db_timezone            => { :default => ->{ :utc }, :valid_values => [:unchanged, :utc, :local] },
    :geo_options            => { :default => ->{ {:geo_system => 'WGS84', :unit => 'm'} } },
    :distributed_lock_class => { :default => ->{ "NoBrainer::Lock" } },
    :lock_options           => { :default => ->{ { :expire => 60, :timeout => 10 } }, :valid_keys => [:expire, :timeout] },
    :per_thread_connection  => { :default => ->{ false }, :valid_values => [true, false] },
    :machine_id             => { :default => ->{ default_machine_id } },
    :criteria_cache_max_entries => { :default => -> { 10_000 } },
  }

  class << self
    attr_accessor(*SETTINGS.keys)

    def auto_create_databases=(value)
      STDERR.puts "[NoBrainer] config.auto_create_databases is no longer active."
      STDERR.puts "[NoBrainer] The current behavior is now to always auto create databases"
    end

    def auto_create_tables=(value)
      STDERR.puts "[NoBrainer] config.auto_create_tables is no longer active."
      STDERR.puts "[NoBrainer] The current behavior is now to always auto create tables"
    end

    def max_retries_on_connection_failure=(value)
      STDERR.puts "[NoBrainer] config.max_retries_on_connection_failure has been removed."
      STDERR.puts "[NoBrainer] Queries are no longer retried upon failures"
    end

    def apply_defaults
      @applied_defaults_for = SETTINGS.keys.reject { |k| instance_variable_defined?("@#{k}") }
      @applied_defaults_for.each { |k| __send__("#{k}=", SETTINGS[k][:default].call) }
    end

    def geo_options=(value)
      @geo_options = value.try(:symbolize_keys)
    end

    def run_options=(value)
      @run_options = value.try(:symbolize_keys)
    end

    def assert_valid_options
      SETTINGS.each do |k,v|
        assert_value_in(k, v[:valid_values]) if v[:valid_values]
        assert_hash_keys_in(k, v[:valid_keys]) if v[:valid_keys]
      end

      validate_urls

      if driver == :em && per_thread_connection
        raise "To use EventMachine, disable per_thread_connection"
      end
    end

    def reset!
      instance_variables.each { |ivar| remove_instance_variable(ivar) }
    end

    def configure(&block)
      @applied_defaults_for.to_a.each do |k|
        remove_instance_variable("@#{k}") if instance_variable_defined?("@#{k}")
      end
      block.call(self) if block
      apply_defaults
      assert_valid_options
      @configured = true

      NoBrainer::ConnectionManager.notify_url_change
    end

    def configured?
      !!@configured
    end

    def assert_value_in(name, valid_values)
      unless __send__(name).in?(valid_values)
        raise ArgumentError.new("Invalid configuration for #{name}: #{__send__(name)}. Valid values are: #{valid_values.inspect}")
      end
    end

    def assert_hash_keys_in(name, valid_keys)
      extra_keys = __send__(name).keys - valid_keys
      unless extra_keys.empty?
        raise ArgumentError.new("Invalid configuration for  #{name}: #{__send__(name)}. Valid keys are: #{valid_keys.inspect}")
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

    def rethinkdb_url=(value)
      self.rethinkdb_urls = [*value]
    end

    def default_rethinkdb_url
      db = ENV['RETHINKDB_DB'] || ENV['RDB_DB']
      db ||= "#{self.app_name}_#{self.environment}" if self.app_name && self.environment
      host = ENV['RETHINKDB_HOST'] || ENV['RDB_HOST'] || 'localhost'
      port = ENV['RETHINKDB_PORT'] || ENV['RDB_PORT']
      user = ENV['RETHINKDB_USER'] || ENV['RDB_USER']
      pass = ENV['RETHINKDB_PASSWORD'] || ENV['RDB_PASSWORD'] || ENV['RETHINKDB_AUTH'] || ENV['RDB_AUTH']
      url = ENV['RETHINKDB_URL'] || ENV['RDB_URL']
      url ||= "rethinkdb://#{"#{user}:#{pass}@" if (user || pass)}#{host}#{":#{port}" if port}/#{db}" if db
      url
    end

    def validate_urls
      # This is not connecting, just validating the format.
      dbs = rethinkdb_urls.compact.map { |url| NoBrainer::Connection.new(url).parsed_uri[:db] }.uniq
      raise "Please specify the app_name and the environment, or a rethinkdb_url" if dbs.size == 0
      raise "All the rethinkdb_urls must specify the same db name (instead of #{dbs.inspect})" if dbs.size != 1
    end

    def default_logger
      defined?(Rails.logger) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end

    def default_durability
      dev_mode? ? :soft : :hard
    end

    def default_max_retries_on_connection_failure
      # TODO remove
      dev_mode? ? 1 : 15
    end

    # XXX Not referencing NoBrainer::Document::PrimaryKey::Generator::MACHINE_ID_MASK
    # because we don't want to load all the document code to speedup boot time.
    MACHINE_ID_BITS = 24
    MACHINE_ID_MASK = (1 << MACHINE_ID_BITS)-1

    def default_machine_id
      return ENV['MACHINE_ID'] if ENV['MACHINE_ID']

      require 'socket'
      require 'digest/md5'

      host = Socket.gethostname
      if host.in? %w(127.0.0.1 localhost)
        raise "Please configure NoBrainer::Config.machine_id due to lack of appropriate hostname (Socket.gethostname = #{host})"
      end

      Digest::MD5.digest(host).unpack("N")[0] & MACHINE_ID_MASK
    end

    def machine_id=(machine_id)
      machine_id = case machine_id
        when Integer    then machine_id
        when /^[0-9]+$/ then machine_id.to_i
        else raise "Invalid machine_id"
      end
      max_id = MACHINE_ID_MASK
      raise "Invalid machine_id (must be between 0 and #{max_id})" unless machine_id.in?(0..max_id)
      @machine_id = machine_id
    end

    def distributed_lock_class
      if @distributed_lock_class.is_a?(String)
        @distributed_lock_class = @distributed_lock_class.constantize
      end
      @distributed_lock_class
    end
  end
end
