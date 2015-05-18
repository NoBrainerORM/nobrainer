module NoBrainer::Document::Validation::Core
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  included do
    # We don't want before_validation returning false to halt the chain.
    define_callbacks :validation, :skip_after_callbacks_if_terminated => true,
                     :scope => [:kind, :name], :terminator => proc { false }
  end

  def valid?(context=nil, options={})
    super(context || (new_record? ? :create : :update))
  end

  def save?(options={})
    options = { :validate => true }.merge(options)

    if options[:validate]
      valid? ? super : false
    else
      super
    end
  end

  SHORTHANDS = { :format => :format, :length => :length, :required => :presence,
                 :uniq => :uniqueness, :unique => :uniqueness, :in => :inclusion }

  module ClassMethods
    def _field(attr, options={})
      super

      shorthands = SHORTHANDS
      shorthands = shorthands.merge(:required => :not_null) if options[:type] == NoBrainer::Boolean
      shorthands.each { |k,v| validates(attr, v => options[k]) if options.has_key?(k) }

      validates(attr, options[:validates]) if options[:validates]
      validates(attr, :length => { :minimum => options[:min_length] }) if options[:min_length]
      validates(attr, :length => { :maximum => options[:max_length] }) if options[:max_length]
    end
  end
end

class ActiveModel::EachValidator
  def should_validate_field?(record, attribute)
    return true unless record.is_a?(NoBrainer::Document)
    return true if record.new_record?

    attr_changed = "#{attribute}_changed?"
    return record.respond_to?(attr_changed) ? record.__send__(attr_changed) : true
  end

  # XXX Monkey Patching :(
  def validate(record)
    attributes.each do |attribute|
      next unless should_validate_field?(record, attribute) # <--- Added
      value = record.read_attribute_for_validation(attribute)
      next if value.is_a?(NoBrainer::Document::AtomicOps::PendingAtomic) # <--- Added
      next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
      validate_each(record, attribute, value)
    end
  end
end
