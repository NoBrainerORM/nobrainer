module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    self.class.selector_for(pk_value)
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
             :scoped, :unscoped,             # Scope
             :where, :where_indexed?, :where_index_name, :where_index_type, # Where
             :with_index, :without_index, :used_index, # Index
             :with_cache, :without_cache,    # Cache
             :count, :empty?, :any?,         # Count
             :delete_all, :destroy_all,      # Delete
             :includes, :preload,            # Preload
             :each, :to_a,                   # Enumerable
             :first, :last, :first!, :last!, :sample, # First
             :min, :max, :sum, :avg,         # Aggregate
             :update_all, :replace_all,      # Update
             :pluck, :without, :lazy_fetch, :without_plucking, # Pluck
             :to => :all

    def all
      NoBrainer::Criteria.new(:model => self)
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

      ([self] + self.descendants).each do |model|
        model.default_scopes << criteria_proc
      end
    end

    def inherited(subclass)
      subclass.default_scopes = self.default_scopes.dup
      super
    end

    def selector_for(pk)
      rql_table.get(pk)
    end

    def find?(pk)
      attrs = NoBrainer.run { selector_for(pk) }
      new_from_db(attrs).tap { |doc| doc.run_callbacks(:find) } if attrs
    end

    def find(pk)
      find?(pk).tap { |doc| raise NoBrainer::Error::DocumentNotFound, "#{self} #{pk_name}: #{pk} not found" unless doc }
    end
    alias_method :find!, :find

    def disable_perf_warnings
      self.perf_warnings_disabled = true
    end
  end
end
