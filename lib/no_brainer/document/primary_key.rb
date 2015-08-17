module NoBrainer::Document::PrimaryKey
  extend NoBrainer::Autoload
  eager_autoload :Generator

  extend ActiveSupport::Concern
  include ActiveModel::Conversion

  DEFAULT_PK_NAME = :id

  def pk_value
    __send__(self.class.pk_name)
  end

  def pk_value=(value)
    __send__("#{self.class.pk_name}=", value)
  end

  def ==(other)
    return super unless self.class == other.class
    return self.equal?(other) if in_atomic?
    !pk_value.nil? && pk_value == other.pk_value
  end
  alias_method :eql?, :==

  delegate :hash, :to => :pk_value

  def cache_key
    "#{self.class.table_name}/#{pk_value}"
  end

  def to_key
    # ActiveModel::Conversion
    [pk_value]
  end

  module ClassMethods
    def pk_name
      class_variable_get(:@@pk_name)
    end

    def define_default_pk
      class_variable_set(:@@pk_name, nil)

      # TODO Maybe we should let the user configure the pk generator
      pk_generator = NoBrainer::Document::PrimaryKey::Generator

      field NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME, :primary_key => true,
        :type => pk_generator.field_type, :default => ->{ pk_generator.generate }
    end

    def field(attr, options={})
      return super unless options[:primary_key]

      if attr != pk_name
        remove_field(pk_name, :set_default_pk => false) if pk_name
        class_variable_set(:@@pk_name, attr)
      end

      options[:index] = true
      options[:readonly] = true
      super
    end

    def remove_field(attr, options={})
      if fields[attr][:primary_key] && options[:set_default_pk] != false
        define_default_pk
      end
      super
    end
  end
end
