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

      if options[:database] || options[:db]
        STDERR.puts "[NoBrainer] `store_in(db: ...)' has been removed. Use `run_with(db: ...)' instead. Sorry."
      end

      options.assert_valid_keys(:table)
      self.store_in_options.merge!(options)
    end

    def table_name
      table = store_in_options[:table]
      table_name = table.is_a?(Proc) ? table.call : table
      table_name.try(:to_s) || root_class.name.tableize.gsub('/', '__')
    end

    def rql_table
      RethinkDB::RQL.new.table(table_name)
    end
  end
end
