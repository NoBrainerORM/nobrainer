class NoBrainer::Enum
  def initialize; raise; end
  def self.inspect; 'Enum'; end
  def self.to_s; inspect; end
  def self.name; inspect; end

  module NoBrainerExtensions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      Symbol.nobrainer_cast_user_to_model(value)
    end

    def nobrainer_cast_db_to_model(value)
      Symbol.nobrainer_cast_db_to_model(value)
    end

    def nobrainer_field_defined(model, attr, options={})
      NoBrainer::Document::Types.load_type_extensions(Symbol)

      unless options[:in].present?
        raise "When using Enum on `#{model}.#{attr}', you must provide the `:in` option to specify values"
      end
      unless options[:in].all? { |v| v.is_a?(Symbol) }
        raise "The `:in` option must specify symbol values"
      end

      model.inject_in_layer :enum do
        extend ActiveSupport::Concern

        const_set(:ClassMethods, Module.new) unless const_defined?(:ClassMethods)

        options[:in].each do |value|
          method = NoBrainer::Enum::NoBrainerExtensions.method_name(value, attr, options)
          if method_defined?("#{method}?")
            raise "The method `#{method}' is already taken. You may specify a :prefix or :suffix option"
          end

          define_method("#{method}?") { read_attribute(attr) == value }
          define_method("#{method}!") { write_attribute(attr, value) }
          const_get(:ClassMethods).__send__(:define_method, "#{method}") { where(attr => value) }
        end
      end
    end

    def nobrainer_field_undefined(model, attr, options={})
      model.inject_in_layer :enum do
        model.fields[attr][:in].each do |value|
          method = NoBrainer::Enum::NoBrainerExtensions.method_name(value, attr, model.fields[attr])
          remove_method("#{method}?")
          remove_method("#{method}!")
          const_get(:ClassMethods).__send__(:remove_method, "#{method}")
        end
      end
    end

    def self.method_name(value, attr, options)
      [options[:prefix] == true ? attr : options[:prefix], value,
       options[:suffix] == true ? attr : options[:suffix]].compact.join("_")
    end
  end
  extend NoBrainerExtensions
end
