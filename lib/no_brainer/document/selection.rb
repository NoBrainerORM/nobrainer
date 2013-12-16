module NoBrainer::Document::Selection
  extend ActiveSupport::Concern

  def selector
    @selector ||= self.class.selector_for(id)
  end

  module ClassMethods
    def all
      sel = NoBrainer::Selection.new(table, :klass => self)
      sel = sel.where(:_type.in => descendants_type_values) unless is_root_class?
      sel
    end

    def scope(name, selection)
      singleton_class.class_eval do
        if selection.is_a?(Proc)
          define_method(name) { |*args| selection.call(*args) }
        else
          define_method(name) { selection }
        end
      end
    end

    delegate :count, :where, :order_by, :first, :last, :to => :all

    def selector_for(id)
      # TODO Pass primary key if not default
      NoBrainer::Selection.new(table.get(id), :klass => self)
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
