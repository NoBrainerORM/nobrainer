require 'no_brainer/document'
require 'active_support/core_ext/array/wrap'

module NoBrainer
  class Array
    # delegate casting methods to each array element, if defined
    %i(nobrainer_cast_user_to_model nobrainer_cast_model_to_db nobrainer_cast_db_to_model).each do |method|
      redefine_singleton_method(method) do |values|
        ::Array.wrap(values).map do |value|
          if value.class.respond_to?(method)
            value.class.__send__(method, value)
          else
            value
          end
        end
      end
    end

    # convenience method to create a TypedArray
    def self.of(object_type = nil, &object_type_proc)
      NoBrainer::TypedArray.of(object_type, &object_type_proc)
    end
  end

  class TypedArray < ::Array
    def self.of(object_type = nil, &object_type_proc)
      object_type ||= object_type_proc
      unless object_type
        raise ArgumentError, "Expected either Object or block"
      end

      array_type = ::Class.new(TypedArray) do
        define_singleton_method(:object_type,
          if object_type.respond_to?(:call)
            # wait to resolve object type until first use
            ->{ @object_type ||= resolve_object_type(object_type) }
          else
            object_type = resolve_object_type(object_type)
            ->{ object_type }
          end
        )
      end
    end

    def self.resolve_object_type(type)
      type = type.call  if type.respond_to?(:call)
      NoBrainer::Document::Types.load_type_extensions(type)
      type
    end
    private_class_method :resolve_object_type

    def self.name
      str = String.new "Array"
      str += "(#{object_type.name})"  if respond_to?(:object_type)
      str
    end

    # delegate cast methods to object_type cast methods, if defined
    def self.nobrainer_cast_user_to_model(values)
      cast_type = object_type.respond_to?(:nobrainer_cast_user_to_model) && object_type
      values = ::Array.wrap(values).map do |value|
        value = cast_type.nobrainer_cast_user_to_model(value)  if cast_type
        unless value.is_a?(object_type)
          raise NoBrainer::Error::InvalidType, type: object_type.name, value: value
        end
        value
      end
      new(values)
    end

    def self.nobrainer_cast_model_to_db(values)
      values = ::Array.wrap(values)
      if object_type.respond_to?(:nobrainer_cast_model_to_db)
        values.map { |value| object_type.nobrainer_cast_model_to_db(value) }
      else
        values
      end
    end

    def self.nobrainer_cast_db_to_model(values)
      values = ::Array.wrap(values)
      if object_type.respond_to?(:nobrainer_cast_db_to_model)
        values.map { |value| object_type.nobrainer_cast_db_to_model(value) }
      else
        values
      end
    end
  end
end
