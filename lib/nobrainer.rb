require 'rethinkdb'
require 'active_support/core_ext'

module NoBrainer
  extend ActiveSupport::Autoload
  autoload :Document
  autoload :Connection
  autoload :Database
  autoload :Error
  autoload :QueryRunner
  autoload :Selection
  autoload :Relation

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
