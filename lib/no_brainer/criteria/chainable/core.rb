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

  def compile_criteria
    # This method is overriden by other modules.
    # compile_criteria returns a criteria that will be used to generate the RQL.
    # This is useful to apply the class default scope at the very end of the chain.
    self
  end

  def compile_rql
    # This method is overriden by other modules.
    raise "Criteria not bound" unless root_rql
    root_rql
  end

  def to_rql
    compile_criteria.compile_rql
  end

  def inspect
    # rescue super because sometimes root_rql is not set.
    to_rql.inspect rescue super
  end

  def run
    NoBrainer.run { to_rql }
  end
end
