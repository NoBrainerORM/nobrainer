module NoBrainer::Document::Types
  extend ActiveSupport::Concern

  module CastingRules
    extend self
    InvalidType = NoBrainer::Error::InvalidType

    def String(value)
      case value
      when Symbol then value.to_s
      else raise InvalidType
      end
    end

    def Integer(value)
      case value
      when String
        value = value.strip.gsub(/^\+/, '')
        value.to_i.tap { |new_value| new_value.to_s == value or raise InvalidType }
      when Float
        value.to_i.tap { |new_value| new_value.to_f == value or raise InvalidType }
      else raise InvalidType
      end
    end

    def Float(value)
      case value
      when Integer then value.to_f
      when String
        value = value.strip.gsub(/^\+/, '')
        value = value.gsub(/0+$/, '') if value['.']
        value = value.gsub(/\.$/, '')
        value = "#{value}.0" unless value['.']
        value.to_f.tap { |new_value| new_value.to_s == value or raise InvalidType }
      else raise InvalidType
      end
    end

    def Boolean(value)
      case value
      when TrueClass  then true
      when FalseClass then false
      when String, Integer
        value = value.to_s.strip.downcase
        return true  if value.in? %w(true yes t 1)
        return false if value.in? %w(false no f 0)
        raise InvalidType
      else raise InvalidType
      end
    end

    def Symbol(value)
      case value
      when String
        value = value.strip
        raise InvalidType if value.empty?
        value.to_sym
      else raise InvalidType
      end
    end

    def lookup(type)
      CastingRules.method(type.to_s)
    rescue NameError
      proc { raise InvalidType }
    end

    def cast(value, type, type_cast_method)
      return value if value.nil? || type.nil? || value.is_a?(type)
      type_cast_method.call(value)
    end
  end

  included do
    # We namespace our fake Boolean class to avoid polluting the global namespace
    class_exec do
      class Boolean
        def initialize; raise; end
        def self.inspect; 'Boolean'; end
        def self.to_s; inspect; end
        def self.name; inspect; end
      end
    end
    before_validation :add_type_errors
  end

  def add_type_errors
    return unless @pending_type_errors
    @pending_type_errors.each do |name, error|
      errors.add(name, :invalid_type, :type => error.human_type_name)
    end
  end

  module ClassMethods
    def cast_value_for(attr, value)
      attr = attr.to_sym
      field_def = fields[attr]
      return value unless field_def && field_def[:type]
      NoBrainer::Document::Types::CastingRules.cast(value, field_def[:type], field_def[:type_cast_method])
    rescue NoBrainer::Error::InvalidType => error
      error.type = field_def[:type]
      error.value = value
      error.attr_name = attr
      raise error
    end

    def _field(attr, options={})
      super

      inject_in_layer :types do
        define_method("#{attr}=") do |value|
          begin
            value = self.class.cast_value_for(attr, value)
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

    def field(attr, options={})
      if options[:type]
        type_cast_method = NoBrainer::Document::Types::CastingRules.lookup(options[:type])
        options = options.merge(:type_cast_method => type_cast_method)
      end
      super
    end
  end
end
