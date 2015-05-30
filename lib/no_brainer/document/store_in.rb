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

      if options[:database]
        STDERR.puts "[NoBrainer] `store_in(database: ...)' is deprecated, please use `store_in(db: ...)' instead"
        options[:db] = options.delete(:database)
      end

      options.assert_valid_keys(:db, :table)
      self.store_in_options.merge!(options)
    end

    def database_name
      STDERR.puts "[NoBrainer] `database_name is deprecated, please use `db_name' instead"
      db_name
    end

    def db_name
      db = self.store_in_options[:db]
      (db.is_a?(Proc) ? db.call : db).try(:to_s)
    end

    def table_name
      table = store_in_options[:table]
      table_name = table.is_a?(Proc) ? table.call : table
      table_name.try(:to_s) || root_class.name.tableize.gsub('/', '__')
    end

    def rql_table
      db = self.db_name
      rql = RethinkDB::RQL.new
      rql = rql.db(db) if db
      rql.table(table_name)
    end
  end
end
