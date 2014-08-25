module NoBrainer::Criteria::Aggregate
  extend ActiveSupport::Concern

  def min(*a, &b)
    instantiate_doc NoBrainer.run { self.without_ordering.to_rql.min(*klass.with_fields_aliased(a), &b) }
  end

  def max(*a, &b)
    instantiate_doc NoBrainer.run { self.without_ordering.to_rql.max(*klass.with_fields_aliased(a), &b) }
  end

  def sum(*a, &b)
    NoBrainer.run { self.without_ordering.to_rql.sum(*klass.with_fields_aliased(a), &b) }
  end

  def avg(*a, &b)
    NoBrainer.run { self.without_ordering.to_rql.avg(*klass.with_fields_aliased(a), &b) }
  end
end
