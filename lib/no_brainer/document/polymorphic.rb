module NoBrainer::Document::Polymorphic
  extend ActiveSupport::Concern
  include ActiveSupport::DescendantsTracker

  included do
    class_attribute :root_class
    self.root_class = self
  end

  def reset_attributes
    super
    self.class.tap {|klass| 
      self._type = klass.type_value unless klass.is_root_class?
    }
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.field :_type if is_root_class?
    end

    def type_value
      name
    end

    def descendants_type_values
      ([self] + descendants).map(&:type_value)
    end

    def is_root_class?
      self == root_class
    end

    def klass_from_attrs(attrs)
      attrs['_type'].try(:constantize) || root_class
    end
  end
end
