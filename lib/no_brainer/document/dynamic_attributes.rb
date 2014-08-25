module NoBrainer::Document::DynamicAttributes
  extend ActiveSupport::Concern

  def read_attribute(name)
    if self.respond_to?("#{name}") 
      super
    else
      assert_access_field(name)
      @_attributes[name].tap { |value| attribute_may_change(name, value) if value.respond_to?(:size) }
    end
  end

  def write_attribute(name, value)
    if self.respond_to?("#{name}=")
      super
    else
      attribute_may_change(name)
      @_attributes[name] = value
      clear_missing_field(name)
      value
    end
  end

  def readable_attributes
    @_attributes.keys
  end
end
