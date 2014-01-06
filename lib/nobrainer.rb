if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9')
  raise 'Please use Ruby 1.9 or later'
end

# Load only what we need from ActiveSupport
require 'active_support/concern'
require 'active_support/lazy_load_hooks'
%w(module/delegation module/attribute_accessors class/attribute object/blank
   object/inclusion object/duplicable hash/keys hash/reverse_merge array/extract_options)
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
      @connection.try(:disconnect)
      @connection = nil
    end

    def disconnect_if_url_changed
      if @connection && @connection.uri != NoBrainer::Config.rethinkdb_url
        disconnect
      end
    end

    # Not using modules to extend, it's nicer to see the NoBrainer module API here.
    delegate :db_create, :db_drop, :db_list,
             :table_create, :table_drop, :table_list,
             :drop!, :purge!, :to => :connection
    delegate :run, :to => 'NoBrainer::QueryRunner'
    delegate :update_indexes, :to => 'NoBrainer::IndexManager'
    delegate :with, :with_database, :to => 'NoBrainer::QueryRunner::RunOptions'
    delegate :configure, :logger, :to => 'NoBrainer::Config'

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
