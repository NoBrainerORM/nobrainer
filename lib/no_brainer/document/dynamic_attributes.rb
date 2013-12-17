module NoBrainer::Document::DynamicAttributes
  extend ActiveSupport::Concern

  def read_attribute(name)
    self.respond_to?("#{name}") ? super : attributes[name.to_s]
  end

  def write_attribute(name, value)
    self.respond_to?("#{name}=") ? super : attributes[name.to_s] = value
  end
end
