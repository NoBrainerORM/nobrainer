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

  autoload :Document, :Connection, :Database, :Error, :QueryRunner, :Criteria, :Relation,
           :DecoratedSymbol, :IndexManager, :Loader

  DecoratedSymbol.hook

  class << self
    # Note: we always access the connection explicitly, so that in the future,
    # we can refactor to return a connection depending on the context.
    # Note that a connection is tied to a database in NoBrainer.
    attr_accessor :logger

    def connect(uri)
      @connection = Connection.new(uri).tap { |c| c.connect }
    end

    def connection
      return @connection if @connection
      return connect(ENV['RETHINKDB_URL']) if ENV['RETHINKDB_URL']

      app_name = Rails.application.class.parent_name.underscore rescue 'app_name'
      raise "NoBrainer is not connected.\n" +
            "Please add the following in your initializers:\n" +
            "  NoBrainer.connect 'rethinkdb://localhost/#{app_name}'\n" +
            "You may also use the RETHINKDB_URL environment variable"
    end

    # No not use modules to extend, it's nice to see the NoBrainer module API here.
    delegate :db_create, :db_drop, :db_list, :database, :to => :connection
    delegate :table_create, :table_drop, :table_list,
             :drop!, :purge!, :to => :database
    delegate :run, :to => QueryRunner
    delegate :update_indexes, :to => IndexManager

    def rails3?
      return @rails3 unless @rails3.nil?
      @rails3 = Gem.loaded_specs['activemodel'].version >= Gem::Version.new('3') &&
                Gem.loaded_specs['activemodel'].version <  Gem::Version.new('4')
    end
  end

  self.logger = defined?(Rails) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
end
