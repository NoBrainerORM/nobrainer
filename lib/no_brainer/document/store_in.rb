require 'rethinkdb'

module NoBrainer::Document::StoreIn
  extend ActiveSupport::Concern

  included do
    cattr_accessor :store_in_options, :instance_accessor => false
    self.store_in_options = {}
  end

  module ClassMethods
    def store_in(options)
      raise "store_in() must be called on the parent class" unless is_root_class?
      self.store_in_options.merge!(options)
    end

    def database_name
      db = self.store_in_options[:database]
      db.is_a?(Proc) ? db.call : db
    end

    def table_name
      table = store_in_options[:table]
      table_name = table.is_a?(Proc) ? table.call : table
      table_name || root_class.name.tableize.gsub('/', '__')
    end

    def rql_table
      db = self.database_name
      rql = RethinkDB::RQL.new
      rql = rql.db(db) if db
      rql.table(table_name)
    end
  end
end
