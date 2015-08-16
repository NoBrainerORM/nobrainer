module NoBrainer::Document::Readonly
  extend ActiveSupport::Concern

  module ClassMethods
    def field(attr, options={})
      super
      inject_in_layer :readonly do
        case options[:readonly]
        when true
          define_method("#{attr}=") do |value|
            unless new_record?
              if read_attribute(attr) != value
                raise NoBrainer::Error::ReadonlyField.new("#{attr} is readonly")
              end
            end
            super(value)
          end
        when false then remove_method("#{attr}=") if method_defined?("#{attr}=")
        end
      end
    end

    def remove_field(attr, options={})
      super
      inject_in_layer :readonly do
        remove_method("#{attr}=") if method_defined?("#{attr}=")
      end
    end
  end
end
