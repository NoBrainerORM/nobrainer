module NoBrainer::Document::Criteria
  extend ActiveSupport::Concern

  def selector
    @selector ||= self.class.selector_for(id)
  end

  included do
    class_attribute :default_scope_proc
  end

  module ClassMethods
    delegate :count, :first, :last, :scoped, :unscoped,
             :with_index, :without_index, :used_index, :indexed?, :where, :order_by,
             :update_all, :delete_all, :destroy_all,
             :inc_all, :dec_all, :to => :all

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
      self.default_scope_proc = criteria.is_a?(Proc) ? criteria : proc { criteria }
    end

    def selector_for(id)
      # TODO Pass primary key if not default
      where(:id => id)
    end

    # XXX this doesn't have the same semantics as
    # other ORMs. the equivalent is find!.
    def find(id)
      selector_for(id).first
    end

    def find!(id)
      find(id).tap do |doc|
        doc or raise NoBrainer::Error::DocumentNotFound, "#{self.class} id #{id} not found"
      end
    end
  end
end
