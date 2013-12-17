module NoBrainer::Document::Polymorphic
  extend ActiveSupport::Concern
  include ActiveSupport::DescendantsTracker

  included do
    class_attribute :root_class
    self.root_class = self
  end

  def assign_attributes(*args)
    super
    self._type ||= self.class.type_value unless self.class.is_root_class?
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

    def all
      criterion = super
      criterion = criterion.where(:_type.in => descendants_type_values) unless is_root_class?
      criterion
    end
  end
end
