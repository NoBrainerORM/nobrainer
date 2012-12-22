require 'rethinkdb'
require 'active_support/core_ext'

module NoBrainer
  extend ActiveSupport::Autoload
  autoload :Base
  autoload :Connection
  autoload :Database
  autoload :Error
  autoload :Query

  class << self
    # XXX In the future we can make connection context aware
    attr_accessor :connection

    def connect(uri)
      self.connection = Connection.new(uri).tap { |c| c.connect }
    end

    # No extend, we want to see the API clearly
    delegate :db_create, :db_drop, :db_list, :database, :to => :connection
    delegate :table_create, :table_drop, :table_list, :purge!, :to => :database
    delegate :run, :to => Query
  end
end
