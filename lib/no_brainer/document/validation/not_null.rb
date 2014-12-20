module NoBrainer::Document::Validation::NotNull
  extend ActiveSupport::Concern

  module ClassMethods
    def validates_not_null(*attr_names)
      validates_with(NotNullValidator, _merge_attributes(attr_names))
    end
  end

  class NotNullValidator < ActiveModel::EachValidator
    def validate_each(doc, attr, value)
      doc.errors.add(attr, :undefined, options) if value.nil?
    end
  end
end
