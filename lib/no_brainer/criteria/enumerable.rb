module NoBrainer::Criteria::Enumerable
  extend ActiveSupport::Concern

  def each(options={}, &block)
    return enum_for(:each, options) unless block
    self.run.each { |attrs| block.call(instantiate_doc(attrs)) }
    self
  end

  def to_a
    each.to_a.freeze
  end

  # TODO test that
  def respond_to?(name, include_private = false)
    super || [].respond_to?(name)
  end

  # TODO Make something a bit more efficent ?
  def method_missing(name, *args, &block)
    return super unless [].respond_to?(name)
    to_a.__send__(name, *args, &block)
  end
end
