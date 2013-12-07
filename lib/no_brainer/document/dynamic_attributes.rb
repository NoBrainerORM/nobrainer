module NoBrainer::Document::DynamicAttributes
  extend ActiveSupport::Concern

  def [](name)
    attributes[name.to_s]
  end

  def []=(name, value)
    attributes[name.to_s] = value
  end

end