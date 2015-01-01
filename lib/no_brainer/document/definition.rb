module NoBrainer::Document::Definition
  extend ActiveSupport::Concern

  module ClassMethods
    def validates_definition_of(*attr_names)
      validates_with DefinitionValidator, _merge_attributes(attr_names)
    end
  end

  class DefinitionValidator < ActiveModel::EachValidator

    def validate_each(doc, attr, value)
      doc.errors.add(attr, :undefined, options) if value.nil?
    end
  end
end
