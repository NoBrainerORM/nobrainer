require 'time'

module NoBrainer::Document::Types
  extend ActiveSupport::Concern

  module CastUserToModel
    extend self
    InvalidType = NoBrainer::Error::InvalidType

    def String(value)
      case value
      when String then value
      when Symbol then value.to_s
      else raise InvalidType
      end
    end

    def Integer(value)
      case value
      when Integer then value
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
      when Float   then value
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
      when Symbol then value
      when String
        value = value.strip
        raise InvalidType if value.empty?
        value.to_sym
      else raise InvalidType
      end
    end

    def Time(value)
      case value
      when Time then time = value
      when String
        value = value.strip
        time = Time.parse(value) rescue (raise InvalidType)
        raise InvalidType unless time.iso8601 == value
      else raise InvalidType
      end

      case NoBrainer::Config.user_timezone
      when :local     then time.getlocal
      when :utc       then time.utc
      when :unchanged then time
      end
    end

    def lookup(type)
      public_method(type.to_s)
    rescue NameError
      ->(value) { raise InvalidType unless value.is_a?(type) }
    end
  end

  module CastDBToModel
    extend self

    def Symbol(value)
      value.to_sym rescue (value.to_s.to_sym rescue value)
    end

    def Time(value)
      return value unless value.is_a?(Time)

      case NoBrainer::Config.user_timezone
      when :local     then value.getlocal
      when :utc       then value.utc
      when :unchanged then value
      end
    end

    def lookup(type)
      public_method(type.to_s)
    rescue NameError
      nil
    end
  end

  module CastModelToDB
    extend self

    def Time(value)
      return value unless value.is_a?(Time)

      case NoBrainer::Config.db_timezone
      when :local     then value.getlocal
      when :utc       then value.utc
      when :unchanged then value
      end
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
    singleton_class.send(:attr_accessor, :cast_db_to_model_fields)
    singleton_class.send(:attr_accessor, :cast_model_to_db_fields)
    self.cast_db_to_model_fields = Set.new
    self.cast_model_to_db_fields = Set.new
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
      self.class.cast_db_to_model_fields.each do |attr|
        @_attributes[attr] = self.class.cast_db_to_model_for(attr, @_attributes[attr])
      end
    end
  end

  module ClassMethods
    def __cast__(what, attr, value, options={})
      field_def = fields[attr.to_sym]
      return value if value.nil? || !field_def || field_def[what].nil?
      field_def[what].call(value)
    rescue NoBrainer::Error::InvalidType => error
      error.type = field_def[:type]
      error.value = value
      error.attr_name = attr
      raise error
    end

    def cast_user_to_model_for(attr, value)
      __cast__(:cast_user_to_model, attr, value)
    end

    def cast_model_to_db_for(attr, value)
      __cast__(:cast_model_to_db, attr, value)
    end

    def cast_db_to_model_for(attr, value)
      __cast__(:cast_db_to_model, attr, value)
    end

    def cast_user_to_db_for(attr, value)
      value = cast_user_to_model_for(attr, value)
      cast_model_to_db_for(attr, value)
    end

    def persistable_attributes(attrs)
      attr_names = cast_model_to_db_fields & attrs.keys
      if attr_names.present?
        attrs = attrs.dup
        attr_names.each do |attr|
          attrs[attr] = cast_model_to_db_for(attr, attrs[attr])
        end
      end
      attrs
    end

    def inherited(subclass)
      super
      subclass.cast_db_to_model_fields = self.cast_db_to_model_fields.dup
      subclass.cast_model_to_db_fields = self.cast_model_to_db_fields.dup
    end

    def _field(attr, options={})
      super

      if options[:cast_db_to_model]
        ([self] + descendants).each do |klass|
          klass.cast_db_to_model_fields << attr.to_s
        end
      end

      if options[:cast_model_to_db]
        ([self] + descendants).each do |klass|
          klass.cast_model_to_db_fields << attr.to_s
        end
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

    def field(attr, options={})
      type = options[:type]
      if type
        if type.to_s.in? %w(DateTime Date)
          STDERR.puts "[NoBrainer] At: #{NoBrainer.user_caller}"
          STDERR.puts "[NoBrainer] #{type} types are not supported. Please use the Time type instead."
          STDERR.puts "[NoBrainer] You may read about this caveat at the bottom of http://nobrainer.io/docs/types/"
        end

        cast_methods = {}
        cast_methods[:cast_user_to_model]  = type.method(:nobrainer_cast_user_to_model) rescue nil
        cast_methods[:cast_db_to_model]    = type.method(:nobrainer_cast_db_to_model)   rescue nil
        cast_methods[:cast_model_to_db]    = type.method(:nobrainer_cast_model_to_db)   rescue nil
        cast_methods[:cast_user_to_model] ||= NoBrainer::Document::Types::CastUserToModel.lookup(type)
        cast_methods[:cast_db_to_model]   ||= NoBrainer::Document::Types::CastDBToModel.lookup(type)
        cast_methods[:cast_model_to_db]   ||= NoBrainer::Document::Types::CastModelToDB.lookup(type)
        options = cast_methods.merge(options)
      end
      super
    end

    def _remove_field(attr, options={})
      super

      ([self] + descendants).each do |klass|
        klass.cast_db_to_model_fields.delete(attr.to_s)
        klass.cast_model_to_db_fields.delete(attr.to_s)
      end

      inject_in_layer :types do
        remove_method("#{attr}=")
        remove_method("#{attr}?") if method_defined?("#{attr}?")
      end
    end
  end
end
