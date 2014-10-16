module NoBrainer::Criteria::Aggregate
  extend ActiveSupport::Concern

  def min(*a, &b)
    instantiate_doc run { aggregate_rql(:min, *a, &b) }
  end

  def max(*a, &b)
    instantiate_doc run { aggregate_rql(:max, *a, &b) }
  end

  def sum(*a, &b)
    run { aggregate_rql(:sum, *a, &b) }
  end

  def avg(*a, &b)
    run { aggregate_rql(:avg, *a, &b) }
  end

  private

  def aggregate_rql(type, *a, &b)
    rql = without_ordering.without_plucking.to_rql
    rql = rql.__send__(type, *klass.with_fields_aliased(a), &b)
    rql = rql.default(nil) unless type == :sum
    rql
  end
end
