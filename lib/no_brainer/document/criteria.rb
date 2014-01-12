module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    self.class.selector_for(id)
  end

  included { cattr_accessor :default_scope_proc, :instance_accessor => false }

  module ClassMethods
    delegate :to_rql,                        # Core
             :limit, :offset, :skip,         # Limit
             :order_by, :reverse_order,      # OrderBy
             :scoped, :unscoped,             # Scope
             :where, :with_index, :without_index, :used_index, :indexed?, # Where
             :with_cache, :without_cache,    # Cache
             :count, :empty?, :any?,         # Count
             :delete_all, :destroy_all,      # Delete
             :includes, :preload,            # Preload
             :each, :to_a,                   # Enumerable
             :first, :last, :first!, :last!, # First
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

    def selector_for(id)
      # TODO Pass primary key if not default
      unscoped.where(:id => id)
    end

    # XXX this doesn't have the same semantics as
    # other ORMs. the equivalent is find!.
    def find(id)
      selector_for(id).first
    end

    def find!(id)
      find(id).tap do |doc|
        raise NoBrainer::Error::DocumentNotFound, "#{self.class} id #{id} not found" unless doc
      end
    end
  end
end
