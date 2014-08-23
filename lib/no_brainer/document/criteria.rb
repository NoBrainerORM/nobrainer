module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    self.class.selector_for(pk_value)
  end

  included { cattr_accessor :default_scope_proc, :instance_accessor => false }

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
             :to => :all

    def all
      NoBrainer::Criteria.new(:klass => self)
    end

    def scope(name, criteria=nil, &block)
      criteria ||= block
      criteria_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
      singleton_class.class_eval do
        define_method(name) { |*args| criteria_proc.call(*args) }
      end
    end

    def default_scope(criteria=nil, &block)
      criteria ||= block
      raise "store_in() must be called on the parent class" unless is_root_class?
      self.default_scope_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
    end

    def selector_for(pk)
      rql_table.get(pk)
    end

    # XXX this doesn't have the same semantics as other ORMs. the equivalent is find!.
    def find(pk)
      attrs = NoBrainer.run { selector_for(pk) }
      new_from_db(attrs).tap { |doc| doc.run_callbacks(:find) } if attrs
    end

    def find!(pk)
      find(pk).tap do |doc|
        raise NoBrainer::Error::DocumentNotFound, "#{self} #{pk_name}: #{pk} not found" unless doc
      end
    end
  end
end
