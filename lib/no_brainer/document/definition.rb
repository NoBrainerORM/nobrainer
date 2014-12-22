module NoBrainer::Document::Definition
  extend ActiveSupport::Concern

  included do
    singleton_class.send(:attr_accessor, :defined_validators)
    self.defined_validators = []
  end

  module ClassMethods
    def validates_definition_of(*attr_names)
      validates_with DefinitionValidator, _merge_attributes(attr_names)
    end

    def inherited(subclass)
      subclass.defined_validators = self.defined_validators.dup
      super
    end
  end

  class DefinitionValidator < ActiveModel::EachValidator
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
      doc.errors.add(attr, :undefined, options) if value.nil?
    end
  end
end
