module NoBrainer::Criteria::Aggregate
  extend ActiveSupport::Concern

  def min(*a, &b)
    order_by(a, &b).first
  end

  def max(*a, &b)
    order_by(a, &b).last
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
    rql = rql.__send__(type, *model.with_fields_aliased(a), &b)
    rql = rql.default(nil) unless type == :sum
    rql
  end
end
