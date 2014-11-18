module NoBrainer::Document::PrimaryKey
  extend NoBrainer::Autoload
  autoload :Generator

  extend ActiveSupport::Concern

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

  module ClassMethods
    def define_default_pk
      class_variable_set(:@@pk_name, nil)
      field NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME, :primary_key => :default
    end

    def define_pk(attr)
      if fields[pk_name].try(:[], :primary_key) == :default
        remove_field(pk_name, :set_default_pk => false)
      end
      class_variable_set(:@@pk_name, attr)
    end

    def pk_name
      class_variable_get(:@@pk_name)
    end

    def _field(attr, options={})
      super
      define_pk(attr) if options[:primary_key]
    end

    def field(attr, options={})
      if options[:primary_key]
        options = options.merge(:readonly => true) if options[:readonly].nil?
        options = options.merge(:index => true)

        if options[:type].in?([String, nil]) && options[:default].nil?
          options[:type] = String
          options[:default] = ->{ NoBrainer::Document::PrimaryKey::Generator.generate }
        end
      end
      super
    end

    def _remove_field(attr, options={})
      super
      if fields[attr][:primary_key] && options[:set_default_pk] != false
        define_default_pk
      end
    end
  end
end
