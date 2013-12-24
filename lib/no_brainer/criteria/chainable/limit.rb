module NoBrainer::Criteria::Chainable::Limit
  # TODO Test these guys
  extend ActiveSupport::Concern

  included { attr_accessor :_skip, :_limit }

  def limit(value)
    chain { |criteria| criteria._limit = value }
  end

  def skip(value)
    chain { |criteria| criteria._skip = value }
  end
  alias_method :offset, :skip

  def merge!(criteria)
    super
    self._skip = criteria._skip if criteria._skip
    self._limit = criteria._limit if criteria._limit
    self
  end

  private

  def compile_rql
    rql = super
    rql = rql.skip(_skip) if _skip
    rql = rql.limit(_limit) if _limit
    rql
  end
end
