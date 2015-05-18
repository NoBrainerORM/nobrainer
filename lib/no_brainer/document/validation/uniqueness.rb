module NoBrainer::Document::Validation::Uniqueness
  extend ActiveSupport::Concern

  def save?(options={})
    lock_unique_fields
    super
  ensure
    unlock_unique_fields
  end

  def _lock_key_from_field(field)
    value = read_attribute(field).to_s
    ['nobrainer', self.class.database_name || NoBrainer.connection.parsed_uri[:db],
     self.class.table_name, field, value.empty? ? 'nil' : value].join(':')
  end

  def lock_unique_fields
    return unless NoBrainer::Config.distributed_lock_class && !self.class.unique_validators.empty?

    self.class.unique_validators
      .map { |validator| validator.attributes.map { |attr| [attr, validator] } }
      .flatten(1)
      .select { |f, validator| validator.should_validate_field?(self, f) }
      .map { |f, options| _lock_key_from_field(f) }
      .sort
      .uniq
      .each do |key|
        lock = NoBrainer::Config.distributed_lock_class.new(key)
        lock.lock
        @locked_unique_fields ||= []
        @locked_unique_fields << lock
      end
  end

  def unlock_unique_fields
    return unless @locked_unique_fields
    @locked_unique_fields.pop.unlock until @locked_unique_fields.empty?
  end

  included do
    singleton_class.send(:attr_accessor, :unique_validators)
    self.unique_validators = []
  end

  module ClassMethods
    def validates_uniqueness_of(*attr_names)
      validates_with(UniquenessValidator, _merge_attributes(attr_names))
    end

    def inherited(subclass)
      subclass.unique_validators = self.unique_validators.dup
      super
    end
  end

  class UniquenessValidator < ActiveModel::EachValidator
    attr_accessor :scope

    def initialize(options={})
      super
      model = options[:class]
      self.scope = [*options[:scope]]
      ([model] + model.descendants).each do |_model|
        _model.unique_validators << self
      end
    end

    def should_validate_field?(doc, field)
      doc.new_record? || (scope + [field]).any? { |f| doc.__send__("#{f}_changed?") }
    end

    def validate_each(doc, attr, value)
      criteria = doc.root_class.unscoped.where(attr => value)
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
      criteria.where(scope.map { |k| {k => doc.read_attribute(k)} })
    end

    def exclude_doc(criteria, doc)
      criteria.where(doc.class.pk_name.not => doc.pk_value)
    end
  end
end
