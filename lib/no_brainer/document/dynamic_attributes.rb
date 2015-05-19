module NoBrainer::Document::DynamicAttributes
  extend ActiveSupport::Concern

  def read_attribute(name)
    self.respond_to?("#{name}") ? super : _read_attribute(name)
  end

  def write_attribute(name, value)
    self.respond_to?("#{name}=") ? super : _write_attribute(name, value)
  end

  def readable_attributes
    @_attributes.keys
  end

  module ClassMethods
    def ensure_valid_key!(key)
      # we never raise
    end
  end
end
