module NoBrainer::Document::Validation::Uniqueness
  extend ActiveSupport::Concern

  # XXX we don't use read_attribute_for_validation, which goes through the user
  # getters, but read internal attributes instead. It makes more sense.

  def save?(options={})
    lock_unique_fields
    super
  ensure
    unlock_unique_fields
  end

  def _lock_for_uniqueness_once(key)
    @locked_keys_for_uniqueness ||= {}
    @locked_keys_for_uniqueness[key] ||= NoBrainer::Config.distributed_lock_class.new(key).tap(&:lock)
  end

  def unlock_unique_fields
    @locked_keys_for_uniqueness.to_h.values.each(&:unlock)
    @locked_keys_for_uniqueness = {}
  end

  def lock_unique_fields
    self.class.unique_validators
      .flat_map { |validator| validator.attributes.map { |attr| [attr, validator] } }
      .select { |f, validator| validator.should_validate_field?(self, f) }
      .map { |f, validator| [f, *validator.scope].map { |k| [k, _read_attribute(k)] } }
      .map { |params| self.class._uniqueness_key_name_from_params(params) }
      .sort.each { |key| _lock_for_uniqueness_once(key) }
  end

  included do
    singleton_class.send(:attr_accessor, :unique_validators)
    self.unique_validators = []
    attr_accessor :locked_keys_for_uniqueness
  end

  module ClassMethods
    def _uniqueness_key_name_from_params(params)
      ['uniq', NoBrainer.current_db, self.table_name,
       *params.map { |k,v| [k.to_s, (v = v.to_s; v.empty? ? 'nil' : v)] }.sort
      ].join(':')
    end

    def validates_uniqueness_of(*attr_names)
      validates_with(UniquenessValidator, _merge_attributes(attr_names))
    end

    def inherited(subclass)
      subclass.unique_validators = self.unique_validators.dup
      super
    end
  end

  class UniquenessValidator < ActiveModel::EachValidator
    attr_accessor :scope, :model

    def initialize(options={})
      super
      self.model = options[:class]
      self.scope = [*options[:scope]].map(&:to_sym)

      model.subclass_tree.each do |subclass|
        subclass.unique_validators << self
      end
    end

    def should_validate_field?(doc, field)
      doc.new_record? || (scope + [field]).any? { |f| doc.__send__("#{f}_changed?") }
    end

    def validate_each(doc, attr, value)
      criteria = self.model.unscoped.where(attr => value)
      criteria = apply_scopes(criteria, doc)
      criteria = exclude_doc(criteria, doc) if doc.persisted?
      doc.errors.add(attr, :taken, options.except(:scope).merge(:value => value)) unless criteria.empty?
    rescue NoBrainer::Error::InvalidType
      # We can't run the uniqueness validator: where() won't accept bad types
      # and we have some values that don't have the right type.
      # Note that it's fine to not add errors because the type validations will
      # prevent the document from being saved.
    end

    def apply_scopes(criteria, doc)
      criteria.where(scope.map { |k| {k => doc._read_attribute(k)} })
    end

    def exclude_doc(criteria, doc)
      criteria.where(doc.class.pk_name.not => doc.pk_value)
    end
  end
end
