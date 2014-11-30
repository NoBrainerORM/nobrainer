module NoBrainer::Document::Types
  extend ActiveSupport::Concern

  included { before_validation :add_type_errors }

  def add_type_errors
    return unless @pending_type_errors
    @pending_type_errors.each do |name, error|
      errors.add(name, :invalid_type, :type => error.human_type_name)
    end
  end

  def assign_attributes(attrs, options={})
    super
    if options[:from_db]
      @_attributes = Hash[@_attributes.map do |k,v|
        [k, self.class.cast_db_to_model_for(k, v)]
      end].with_indifferent_access
    end
  end

  module ClassMethods
    def cast_user_to_model_for(attr, value)
      type = fields[attr.to_sym].try(:[], :type)
      return value if type.nil? || value.nil? || value.is_a?(NoBrainer::Document::AtomicOps::PendingAtomic)
      if type.respond_to?(:nobrainer_cast_user_to_model)
        type.nobrainer_cast_user_to_model(value)
      else
        raise NoBrainer::Error::InvalidType unless value.is_a?(type)
        value
      end
    rescue NoBrainer::Error::InvalidType => error
      error.type = type
      error.value = value
      error.attr_name = attr
      raise error
    end

    def cast_model_to_db_for(attr, value)
      type = fields[attr.to_sym].try(:[], :type)
      return value if type.nil? || value.nil? || !type.respond_to?(:nobrainer_cast_model_to_db)
      type.nobrainer_cast_model_to_db(value)
    end

    def cast_db_to_model_for(attr, value)
      type = fields[attr.to_sym].try(:[], :type)
      return value if type.nil? || value.nil? || !type.respond_to?(:nobrainer_cast_db_to_model)
      type.nobrainer_cast_db_to_model(value)
    end

    def cast_user_to_db_for(attr, value)
      value = cast_user_to_model_for(attr, value)
      cast_model_to_db_for(attr, value)
    end

    def persistable_value(k, v, options={})
      cast_model_to_db_for(k, super)
    end

    def _field(attr, options={})
      super

      return unless options[:type]

      NoBrainer::Document::Types.load_type_extensions(options[:type]) if options[:type]

      case options[:type].to_s
      when "NoBrainer::Geo::Circle" then raise "Cannot store circles :("
      when "NoBrainer::Geo::Polygon", "NoBrainer::Geo::LineString"
        raise "Make a request on github if you'd like to store polygons/linestrings"
      end

      inject_in_layer :types do
        define_method("#{attr}=") do |value|
          begin
            value = self.class.cast_user_to_model_for(attr, value)
            @pending_type_errors.try(:delete, attr)
          rescue NoBrainer::Error::InvalidType => error
            @pending_type_errors ||= {}
            @pending_type_errors[attr] = error
          end
          super(value)
        end

        define_method("#{attr}?") { !!read_attribute(attr) } if options[:type] == Boolean
      end
    end

    def _remove_field(attr, options={})
      super

      inject_in_layer :types do
        remove_method("#{attr}=")
        remove_method("#{attr}?") if method_defined?("#{attr}?")
      end
    end
  end

  require File.join(File.dirname(__FILE__), 'types', 'binary')
  require File.join(File.dirname(__FILE__), 'types', 'boolean')
  Binary = NoBrainer::Binary
  Boolean = NoBrainer::Boolean
  Geo = NoBrainer::Geo

  class << self
    mattr_accessor :loaded_extensions
    self.loaded_extensions = Set.new
    def load_type_extensions(model)
      unless loaded_extensions.include?(model)
        begin
          require File.join(File.dirname(__FILE__), 'types', model.name.underscore)
        rescue LoadError
        end
        loaded_extensions << model
      end
    end
  end
end
