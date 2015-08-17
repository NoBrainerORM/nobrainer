module NoBrainer::Criteria::Enumerable
  extend ActiveSupport::Concern

  def each(options={}, &block)
    return enum_for(:each, options) unless block
    run.tap { |cursor| @cursor = cursor }.each do |attrs|
      return close if @close_cursor
      block.call(instantiate_doc(attrs))
    end
    self
  end

  def close
    @close_cursor = true
    @cursor.close if NoBrainer::Config.driver == :em
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

  delegate :as_json, :to => :each
end
