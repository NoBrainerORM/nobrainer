module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    @selector ||= self.class.selector_for(id)
  end

  included do
    class_attribute :default_scope_proc
  end

  module ClassMethods
    delegate :count, :where, :order_by, :first, :last, :scoped, :unscoped,
             :indexed_where, :without_index, :to => :all

    def all
      NoBrainer::Criteria.new(:root_rql => table, :klass => self)
    end

    def scope(name, criteria)
      criteria_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
      singleton_class.class_eval do
        define_method(name) { |*args| criteria_proc.call(*args) }
      end
    end

    def default_scope(criteria)
      self.default_scope_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
    end

    def selector_for(id)
      # TODO Pass primary key if not default
      NoBrainer::Criteria.new(:root_rql => table.get(id), :klass => self)
    end

    # XXX this doesn't have the same semantics as
    # other ORMs. the equivalent is find!.
    def find(id)
      new_from_db(selector_for(id).run)
    end

    def find!(id)
      find(id).tap do |doc|
        doc or raise NoBrainer::Error::DocumentNotFound, "#{self.class} id #{id} not found"
      end
    end
  end
end
