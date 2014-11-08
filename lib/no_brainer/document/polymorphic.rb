module NoBrainer::Document::Polymorphic
  extend ActiveSupport::Concern
  include ActiveSupport::DescendantsTracker

  included do
    cattr_accessor :root_class, :is_polymorphic
    self.root_class = self
    self.is_polymorphic = false
  end

  def assign_attributes(*args)
    super
    self._type ||= self.class.type_value unless self.class.is_root_class?
  end

  module ClassMethods
    def inherited(subclass)
      subclass.is_polymorphic = true
      super
      subclass.field :_type if is_root_class?
    end

    def type_value
      name
    end

    def is_root_class?
      self == root_class
    end

    def for_each_subclass(&block)
      ([self] + self.descendants).each(&block)
    end

    def descendants_type_values
      for_each_subclass.map(&:type_value)
    end

    def model_from_attrs(attrs)
      attrs['_type'].try(:constantize) || root_class
    end

    def all
      criteria = super
      criteria = criteria.where(:_type.in => descendants_type_values) unless is_root_class?
      criteria
    end
  end
end
