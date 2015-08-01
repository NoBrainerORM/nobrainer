module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    # Used for writes
    self.class.rql_table.get(pk_value)
  end

  included do
    cattr_accessor :perf_warnings_disabled, :instance_accessor => false
    singleton_class.send(:attr_accessor, :default_scopes)
    self.default_scopes = []
  end

  module ClassMethods
    delegate :to_rql,                        # Core
             :raw,                           # Raw
             :limit, :offset, :skip,         # Limit
             :order_by, :reverse_order, :without_ordering, :order_by_indexed?, :order_by_index_name, # OrderBy
             :unscoped,                      # Scope
             :_where, :where, :where_indexed?, :where_index_name, :where_index_type, # Where
             :with_index, :without_index, :used_index, # Index
             :with_cache, :without_cache,    # Cache
             :count, :empty?, :any?,         # Count
             :delete_all, :destroy_all,      # Delete
             :preload, :eager_load,          # EagerLoad
             :each, :to_a,                   # Enumerable
             :first, :last, :first!, :last!, :sample, # First
             :upsert, :upsert!, :first_or_create, :first_or_create!, # FirstOrCreate
             :min, :max, :sum, :avg,         # Aggregate
             :update_all, :replace_all,      # Update
             :changes,                       # Changes
             :pluck, :without, :lazy_fetch, :without_plucking, # Pluck
             :find_by?, :find_by, :find_by!, :find?, :find, :find!, # Find
             :join,                          #Join
             :to => :all

    def all
      NoBrainer::Criteria.new(:initial_run_options => NoBrainer.current_run_options,
                              :model => self)
    end

    def scope(name, criteria=nil, &block)
      criteria ||= block
      criteria_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
      singleton_class.class_eval do
        define_method(name) { |*args| criteria_proc.call(*args) }
      end
    end

    def default_scope(criteria=nil, &block)
      criteria_proc = block || (criteria.is_a?(Proc) ? criteria : proc { criteria })
      raise "default_scope only accepts a criteria or a proc that returns criteria" unless criteria_proc.is_a?(Proc)

      subclass_tree.each do |subclass|
        subclass.default_scopes << criteria_proc
      end
    end

    def inherited(subclass)
      subclass.default_scopes = self.default_scopes.dup
      super
    end

    def disable_perf_warnings
      self.perf_warnings_disabled = true
    end
  end
end
