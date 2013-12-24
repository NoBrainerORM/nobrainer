module NoBrainer::Criteria::Chainable::Core
  extend ActiveSupport::Concern

  included { attr_accessor :options }

  def initialize(options={})
    self.options = options
  end

  def klass
    options[:klass]
  end

  def to_rql
    compile_criteria.__send__(:compile_rql)
  end

  def inspect
    # rescue super because sometimes klass is not set.
    to_rql.inspect rescue super
  end

  def run(rql=nil)
    NoBrainer.run { rql || to_rql }
  end

  def merge!(criteria)
    self.options = self.options.merge(criteria.options)
    self
  end

  def merge(criteria)
    dup.tap { |new_criteria| new_criteria.merge!(criteria) }
  end

  def ==(other)
    return super if other.is_a?(NoBrainer::Criteria)
    return to_a == other if other.is_a?(Enumerable)
    super
  end

  private

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
    raise "Criteria not bound to a class" unless klass
    klass.rql_table
  end
end
