module NoBrainer::Criteria::Chainable::Scope
  extend ActiveSupport::Concern

  def klass
    options[:klass]
  end

  def respond_to?(name, include_private = false)
    super || self.klass.respond_to?(name)
  end

  def method_missing(name, *args, &block)
    return super unless self.klass.respond_to?(name)
    self.klass.method(name).call(*args, &block)
  end
end
