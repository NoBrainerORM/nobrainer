module NoBrainer::Criteria::Chainable::Core
  extend ActiveSupport::Concern

  included { attr_accessor :options }

  def initialize(options={})
    self.options = options
  end

  def root_rql
    options[:root_rql]
  end

  def klass
    options[:klass]
  end

  def merge!(criteria)
    self.options = self.options.merge(criteria.options)
  end

  def merge(criteria)
    dup.tap { |new_criteria| new_criteria.merge!(criteria) }
  end

  def chain(&block)
    tmp = self.class.new(options) # we might want to optimize that thing
    block.call(tmp)
    merge(tmp)
  end

  def must_precompile?
    !options[:precompiled]
  end

  def precompile
    merge(NoBrainer::Criteria.new(:precompiled => true))
  end

  def to_rql
    return precompile.to_rql if must_precompile?
    raise "Criteria not bound" unless root_rql
    root_rql
  end

  def inspect
    root_rql ? to_rql.inspect : super
  end

  def run
    NoBrainer.run { to_rql }
  end
end
