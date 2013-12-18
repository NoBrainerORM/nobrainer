module NoBrainer::Criteria::Chainable::Indexed
  # TODO Test these guys
  extend ActiveSupport::Concern

  included { attr_accessor :index_clause }

  def indexed(attr)
    raise "Use :index_name => value" unless attr.is_a?(Hash)
    raise "Cannot use two indexes" unless attr.size == 1
    chain { |criteria| criteria.index_clause = attr }
  end

  def merge!(criteria)
    super
    return if self.index_clause == criteria.index_clause
    raise "Cannot use two indexes" if self.index_clause
    self.index_clause = criteria.index_clause
  end

  def compile_rql
    rql = super
    rql = rql.get_all(index_clause.first[1], :index => index_clause.first[0]) if index_clause
    rql
  end
end
