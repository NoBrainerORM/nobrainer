module NoBrainer::Criteria::Termination::Enumerable
  extend ActiveSupport::Concern

  def each(options={}, &block)
    return enum_for(:each, options) unless block
    self.run.each { |attrs| block.call(instantiate_doc(attrs)) }
  end

  # TODO test that
  def respond_to?(name, include_private = false)
    super || [].respond_to?(name)
  end

  # TODO Make something a bit more efficent ?
  def method_missing(name, *args, &block)
    return super unless [].respond_to?(name)
    each.to_a.__send__(name, *args, &block)
  end
end
