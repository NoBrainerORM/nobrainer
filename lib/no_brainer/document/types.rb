require 'time'

module NoBrainer::Document::Types
  extend ActiveSupport::Concern

  module CastUserToInternal
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

    def Time(value)
      raise InvalidType unless value.is_a?(String)
      value = value.strip
      time = Time.parse(value) rescue (raise InvalidType)
      raise InvalidType unless time.iso8601 == value
      time
    end

    def lookup(type)
      if type.to_s.in? %w(DateTime Date)
        STDERR.puts "[NoBrainer] At: #{NoBrainer.user_caller}"
        STDERR.puts "[NoBrainer] #{type} types are not supported. Please use the Time type instead."
        STDERR.puts "[NoBrainer] You may read about this caveat at the bottom of http://nobrainer.io/docs/types/"
      end

      public_method(type.to_s)
    rescue NameError
      proc { raise InvalidType }
    end
  end

  module CastInternalToUser
    extend self

    def Symbol(value)
      value.to_sym rescue value
    end

    def lookup(type)
      public_method(type.to_s)
    rescue NameError
      nil
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

    # Fast access for db->user cast methods for performance when reading from
    # the database.
    singleton_class.send(:attr_accessor, :cast_internal_to_user_fields)
    self.cast_internal_to_user_fields = Set.new
  end

  def add_type_errors
    return unless @pending_type_errors
    @pending_type_errors.each do |name, error|
      errors.add(name, :invalid_type, :type => error.human_type_name)
    end
  end

  def assign_attributes(attrs, options={})
    super
    if options[:from_db]
      self.class.cast_internal_to_user_fields.each do |attr|
        field_def = self.class.fields[attr]
        type = field_def[:type]
        value = @_attributes[attr.to_s]
        unless value.nil? || value.is_a?(type)
          @_attributes[attr.to_s] = field_def[:cast_internal_to_user].call(value)
        end
      end
    end
  end

  module ClassMethods
    def cast_user_to_internal_for(attr, value)
      field_def = fields[attr.to_sym]
      return value if !field_def
      type = field_def[:type]
      return value if value.nil? || type.nil? || value.is_a?(type)
      field_def[:cast_user_to_internal].call(value)
    rescue NoBrainer::Error::InvalidType => error
      error.type = field_def[:type]
      error.value = value
      error.attr_name = attr
      raise error
    end

    def cast_user_to_db_for(attr, value)
      cast_user_to_internal_for(attr, value)
      # TODO support custom internal -> db translations.
    end

    def inherited(subclass)
      super
      subclass.cast_internal_to_user_fields = self.cast_internal_to_user_fields.dup
    end

    def _field(attr, options={})
      super

      if options[:cast_internal_to_user]
        ([self] + descendants).each do |klass|
          klass.cast_internal_to_user_fields << attr
        end
      end

      inject_in_layer :types do
        define_method("#{attr}=") do |value|
          begin
            value = self.class.cast_user_to_internal_for(attr, value)
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
        options = {:cast_user_to_internal => NoBrainer::Document::Types::CastUserToInternal.lookup(options[:type]),
                   :cast_internal_to_user => NoBrainer::Document::Types::CastInternalToUser.lookup(options[:type])}.merge(options)
      end
      super
    end

    def _remove_field(attr, options={})
      super
      inject_in_layer :types do
        remove_method("#{attr}=")
        remove_method("#{attr}?") if method_defined?("#{attr}?")
      end
    end
  end
end
