require 'rethinkdb'
require 'active_model'
require 'active_support/core_ext'

if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9')
  raise 'Please use Ruby 1.9 or later'
end

module NoBrainer
  require 'no_brainer/railtie' if defined?(Rails)
  require 'no_brainer/autoload'
  extend NoBrainer::Autoload

  autoload :Config, :Document, :Connection, :Database, :Error, :QueryRunner,
           :Criteria, :Relation, :DecoratedSymbol, :IndexManager, :Loader, :Logging

  DecoratedSymbol.hook

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
      @connection.try(:disconnect)
      @connection = nil
    end

    def disconnect_if_url_changed
      if @connection && @connection.uri != NoBrainer::Config.rethinkdb_url
        disconnect
      end
    end

    # No not use modules to extend, it's nice to see the NoBrainer module API here.
    delegate :db_create, :db_drop, :db_list, :database, :to => :connection
    delegate :table_create, :table_drop, :table_list,
             :drop!, :purge!, :to => :database
    delegate :run, :to => QueryRunner
    delegate :update_indexes, :to => IndexManager
    delegate :with_database, :to => QueryRunner::DatabaseSelector
    delegate :configure, :logger, :to => Config
  end
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/no_brainer/locale/en.yml'
end
