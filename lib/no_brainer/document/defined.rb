module NoBrainer::Document::Defined
  extend ActiveSupport::Concern

  included do
    singleton_class.send(:attr_accessor, :defined_validators)
    self.defined_validators = []
  end

  module ClassMethods
    def validates_defined(*attr_names)
      validates_with DefinedValidator, _merge_attributes(attr_names)
    end

    def inherited(subclass)
      subclass.defined_validators = self.defined_validators.dup
      super
    end
  end

  class DefinedValidator < ActiveModel::EachValidator
    attr_accessor :scope

    def initialize(options={})
      super
      model = options[:class]
      self.scope = [*options[:scope]]
      ([model] + model.descendants).each do |_model|
        _model.defined_validators << self
      end
    end

    def validate_each(doc, attr, value)
      if value.nil?
        doc.errors.add(attr, 'must be defined')
        true
      else
        false
      end
    end
  end
end