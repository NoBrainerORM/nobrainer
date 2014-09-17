require 'active_support'
%w(module/delegation module/attribute_accessors class/attribute object/blank object/inclusion object/deep_dup
   object/try hash/keys hash/indifferent_access hash/reverse_merge hash/deep_merge array/extract_options)
    .each { |dep| require "active_support/core_ext/#{dep}" }

module NoBrainer
  require 'no_brainer/autoload'
  extend NoBrainer::Autoload

  # We eager load things that could be loaded when handling the first web request.
  # Code that is loaded through the DSL of NoBrainer should not be eager loaded.
  autoload :Document, :IndexManager, :Loader, :Fork, :DecoratedSymbol
  eager_autoload :Config, :Connection, :Error, :QueryRunner, :Criteria, :RQL

  class << self
    # A connection is tied to a database.
    def get_new_connection
      url = NoBrainer::Config.rethinkdb_url
      raise "Please specify a database connection to RethinkDB" unless url
      Connection.new(url)
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
      if c = self.current_connection
        c
      else
        self.current_connection = get_new_connection
      end
    end

    def disconnect
      self.current_connection.try(:disconnect, :noreply_wait => true)
      self.current_connection = nil
    end

    def disconnect_if_url_changed
      if @connection && @connection.uri != NoBrainer::Config.rethinkdb_url
        disconnect
      end
    end

    delegate :db_create, :db_drop, :db_list,
             :table_create, :table_drop, :table_list,
             :drop!, :purge!, :to => :connection

    delegate :configure, :logger,   :to => 'NoBrainer::Config'
    delegate :run,                  :to => 'NoBrainer::QueryRunner'
    delegate :update_indexes,       :to => 'NoBrainer::IndexManager'
    delegate :with, :with_database, :to => 'NoBrainer::QueryRunner::RunOptions'

    def jruby?
      RUBY_PLATFORM == 'java'
    end

    def user_caller
      caller.reject { |s| s =~ /\/no_brainer\// }.first
    end
  end

  DecoratedSymbol.hook
  Fork.hook unless jruby?
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/no_brainer/locale/en.yml'
end

require 'no_brainer/railtie' if defined?(Rails)
