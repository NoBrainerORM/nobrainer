require 'rethinkdb'

module NoBrainer::Document::TableConfig
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload :Synchronizer

  VALID_TABLE_CONFIG_OPTIONS = [:name, :durability, :shards, :replicas, :primary_replica_tag, :write_acks]

  included do
    cattr_accessor :table_config_options, :instance_accessor => false
    self.table_config_options = {}
  end

  module ClassMethods
    def store_in(options)
      if options[:table]
        STDERR.puts "[NoBrainer] `store_in(table: ...)' has been removed. Use `table_config(name: ...)' instead."
        options[:name] = options.delete(:table)
      end

      if options[:database] || options[:db]
        raise "`store_in(db: ...)' has been removed. Use `run_with(db: ...)' instead."
      end

      table_config(options)
    end

    def _set_table_config(options)
      raise "table_config() must be used at the parent class, not a subclass" unless is_root_class?

      options.assert_valid_keys(*VALID_TABLE_CONFIG_OPTIONS)
      self.table_config_options.merge!(options)
    end

    def table_name
      name = table_config_options[:name]
      name = name.call if name.is_a?(Proc)
      (name || root_class.name.tableize.gsub('/', '__')).to_s
    end

    def rql_table
      RethinkDB::RQL.new.table(table_name)
    end

    def table_config(options={})
      return _set_table_config(options) unless options.empty?
      NoBrainer::System::TableConfig.new_from_db(NoBrainer.run { rql_table.config })
    end

    def table_status
      NoBrainer::System::TableConfig.new_from_db(NoBrainer.run { rql_table.status })
    end

    def table_stats
      NoBrainer::System::Stats.where(:db => NoBrainer.current_db, :table => table_name).to_a
    end

    def rebalance
      NoBrainer.run { rql_table.rebalance }
      true
    end

    def table_wait
      NoBrainer.run { rql_table.wait }
    end

    def table_create_options
      NoBrainer::Config.table_options
        .merge(table_config_options)
        .merge(:name => table_name)
        .merge(:primary_key => lookup_field_alias(pk_name))
        .reverse_merge(:durability => 'hard')
        .reduce({}) { |h,(k,v)| h[k] = v.is_a?(Symbol) ? v.to_s : v; h } # symbols -> strings
    end

    def sync_table_config(options={})
      c = table_create_options
      table_config.update!(c.slice(:durability, :primary_key, :write_acks))
      NoBrainer.run { rql_table.reconfigure(c.slice(:shards, :replicas, :primary_replica_tag)) }
      true
    end

    def sync_indexes(options={})
      NoBrainer::Document::Index::Synchronizer.new(self).sync_indexes(options)
    end

    def sync_schema(options={})
      sync_table_config(options)
      sync_indexes(options)
    end
  end

  class << self
    def sync_table_config(options={})
      models = NoBrainer::Document.all(:types => [:user, :nobrainer])
      NoBrainer::Document::TableConfig::Synchronizer.new(models).sync_table_config(options)
    end

    def sync_indexes(options={})
      # nobrainer models don't have indexes
      models = NoBrainer::Document.all(:types => [:user])
      NoBrainer::Document::Index::Synchronizer.new(models).sync_indexes(options)
    end

    def sync_schema(options={})
      sync_table_config(options)
      sync_indexes(options)
    end

    def rebalance(options={})
      models = NoBrainer::Document.all(:types => [:user])
      models.each(&:rebalance)
      true
    end
  end
end
