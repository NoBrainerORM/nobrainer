module NoBrainer::Document::Readonly
  extend ActiveSupport::Concern

  module ClassMethods
    def _field(attr, options={})
      super
      inject_in_layer :readonly do
        if options[:readonly]
          define_method("#{attr}=") do |value|
            raise NoBrainer::Error::ReadonlyField.new("#{attr} is readonly") unless new_record?
            super(value)
          end
        else
          remove_method("#{attr}=") if method_defined?("#{attr}=")
        end
      end
    end

    def _remove_field(attr, options={})
      super
      inject_in_layer :readonly do
        remove_method("#{attr}=") if method_defined?("#{attr}=")
      end
    end
  end
end
