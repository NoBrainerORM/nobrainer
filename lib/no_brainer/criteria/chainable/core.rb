module NoBrainer::Criteria::Chainable::Core
  extend ActiveSupport::Concern

  included { attr_accessor :options }

  def initialize(options={})
    self.options = options
  end

  def merge!(criteria)
  end

  def merge(criteria)
    dup.tap { |new_criteria| new_criteria.merge!(criteria) }
  end

  def chain(&block)
    tmp = self.class.new(options) # we might want to optimize that thing
    block.call(tmp)
    merge(tmp)
  end

  def inspect
    klass ? to_rql.inspect : super
  end

  def root_rql
    options[:root_rql]
  end

  def to_rql
    raise "Criteria not bound" unless root_rql
    root_rql
  end

  def run
    NoBrainer.run { to_rql }
  end
end
