require 'active_support'
%w(module/delegation module/attribute_accessors class/attribute object/blank object/inclusion object/deep_dup
   object/try hash/keys hash/indifferent_access hash/reverse_merge hash/deep_merge array/extract_options)
    .each { |dep| require "active_support/core_ext/#{dep}" }

module NoBrainer
  require 'no_brainer/autoload'
  extend NoBrainer::Autoload

  # We eager load things that could be loaded for the first time during the web request
  autoload :Document, :IndexManager, :Loader, :Fork, :DecoratedSymbol
  eager_autoload :Config, :Connection, :Error, :QueryRunner, :Criteria, :Util

  class << self
    # Note: we always access the connection explicitly, so that in the future,
    # we can refactor to return a connection depending on the context.
    # Note that a connection is tied to a database in NoBrainer.
    def connection
      @connection ||= begin
        url = NoBrainer::Config.rethinkdb_url
        raise "Please specify a database connection to RethinkDB" unless url
        Connection.new(url).tap { |c| c.connect }
      end
    end

    def disconnect
      @connection.try(:disconnect, :noreply_wait => true)
      @connection = nil
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
  end

  DecoratedSymbol.hook
  Fork.hook unless jruby?
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/no_brainer/locale/en.yml'
end

require 'no_brainer/railtie' if defined?(Rails)
