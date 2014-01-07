module NoBrainer::Document::Types
  extend ActiveSupport::Concern

  module CastingRules
    extend self

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

    def cast(value, type, cast_method)
      return value if value.nil? || type.nil? || value.is_a?(type)
      cast_method.call(value)
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

  class InvalidType < RuntimeError
    attr_accessor :type
    def initialize(type=nil)
      @type = type
    end

    def validation_error_args
      [:invalid_type, :type => type.to_s.underscore.humanize.downcase]
    end
  end

  def add_type_errors
    return unless @pending_type_errors
    @pending_type_errors.each do |name, error|
      errors.add(name, *error.validation_error_args)
    end
  end

  module ClassMethods
    def field(name, options={})
      super
      return unless options.has_key?(:type)
      name = name.to_sym
      type = options[:type]
      cast_method = NoBrainer::Document::Types::CastingRules.lookup(type)

      inject_in_layer :types do
        define_method("#{name}=") do |value|
          begin
            value = NoBrainer::Document::Types::CastingRules.cast(value, type, cast_method)
            @pending_type_errors.try(:delete, name)
          rescue NoBrainer::Document::Types::InvalidType => error
            error.type ||= type
            @pending_type_errors ||= {}
            @pending_type_errors[name] = error
          end
          super(value)
        end
      end
    end

    def remove_field(name)
      super
      inject_in_layer :types, <<-RUBY, __FILE__, __LINE__ + 1
        undef #{name}=
      RUBY
    end
  end
end
