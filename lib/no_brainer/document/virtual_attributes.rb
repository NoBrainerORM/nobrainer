module NoBrainer::Document::VirtualAttributes
  extend NoBrainer::Autoload
  extend ActiveSupport::Concern

  VALID_VIRTUAL_FIELD_OPTIONS = [:type, :lazy_fetch, :virtual]

  included do
    cattr_accessor :virtual_fields, :instance_accessor => false
  end

  module ClassMethods
    def virtual_field(attr, rql=nil, options={}, &block)
      rql ||= block
      rql_proc = rql.is_a?(Proc) ? rql : proc { rql }
      field(attr, options.merge(:virtual => rql_proc))
    end

    def field(attr, options={})
      return super unless options.key?(:virtual)

      raise "virtual attributes are limited to the root class `#{self.root_class}' for the moment.\n" +
            "Ask on GitHub for polymorphic support." unless is_root_class?

      raise "You cannot index a virtual attribute. Use an index with a lambda expression instead" if options[:index]
      options.assert_valid_keys(*VALID_VIRTUAL_FIELD_OPTIONS)

      self.virtual_fields ||= Set.new
      virtual_fields << attr

      inject_in_layer :virtual_attributes do
        define_method("#{attr}=") do |value|
          raise NoBrainer::Error::ReadonlyField.new("#{attr} is a virtual attribute and thus readonly.")
        end
      end

      super
    end

    def remove_field(attr, options={})
      super

      if fields[:virtual]
        virtual_fields.try(:delete, attr)

        inject_in_layer :virtual_attributes do
          remove_method("#{attr}=")
        end
      end
    end
  end
end
