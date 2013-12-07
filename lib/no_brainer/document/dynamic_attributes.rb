module NoBrainer::Document::DynamicAttributes
  extend ActiveSupport::Concern

  def [](name)
    self.class.has_field?(name) ? super : attributes[name.to_s]
  end

  def []=(name, value)
    self.class.has_field?(name) ? super : attributes[name.to_s] = value
  end
end
