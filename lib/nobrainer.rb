require 'rethinkdb'
require 'active_model'
require 'active_support/core_ext'
require 'no_brainer/railtie' if defined?(Rails)
require 'no_brainer/autoload'

module NoBrainer
  extend NoBrainer::Autoload

  autoload :Document, :Connection, :Database, :Error, :QueryRunner, :Selection, :Relation

  class << self
    # Note: we always access the connection explicitly, so that in the future,
    # we can refactor to return a connection depending on the context.
    # Note that a connection is tied to a database in NoBrainer.
    attr_accessor :connection

    def connect(uri)
      self.connection = Connection.new(uri).tap { |c| c.connect }
    end

    # No not use modules to extend, it's nice to see the NoBrainer module API here.
    delegate :db_create, :db_drop, :db_list, :database, :to => :connection
    delegate :table_create, :table_drop, :table_list,
             :purge!, :to => :database
    delegate :run, :to => QueryRunner
  end
end
