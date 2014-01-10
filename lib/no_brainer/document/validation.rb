module NoBrainer::Document::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  def valid?(context=nil)
    super(context || (new_record? ? :create : :update))
  end

  module ClassMethods
    def field(name, options={})
      super
      validates(name.to_sym, { :presence => true }) if options[:required]
      validates(name.to_sym, options[:validates]) if options[:validates]
    end

    def validates_uniqueness_of(*attr_names)
      validates_with UniquenessValidator, _merge_attributes(attr_names)
    end
  end

  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(doc, attr, value)
      criteria = doc.root_class.unscoped.where(attr => value)
      criteria = apply_scopes(criteria, doc)
      criteria = exclude_doc(criteria, doc) if doc.persisted?
      is_unique = criteria.count == 0
      doc.errors.add(attr, :taken, options.except(:scope).merge(:value => value)) unless is_unique
      is_unique
    end

    def apply_scopes(criteria, doc)
      criteria.where([*options[:scope]].map { |k| {k => doc.read_attribute(k)} })
    end

    def exclude_doc(criteria, doc)
      criteria.where(:id.ne => doc.id)
    end
  end
end
