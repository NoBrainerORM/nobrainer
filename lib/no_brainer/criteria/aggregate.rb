module NoBrainer::Criteria::Aggregate
  extend ActiveSupport::Concern

  def min(*a, &b)
    instantiate_doc NoBrainer.run { self.without_ordering.to_rql.min(*args_lookup_field_alias(a), &b) }
  end

  def max(*a, &b)
    instantiate_doc NoBrainer.run { self.without_ordering.to_rql.max(*args_lookup_field_alias(a), &b) }
  end

  def sum(*a, &b)
    NoBrainer.run { self.without_ordering.to_rql.sum(*args_lookup_field_alias(a), &b) }
  end

  def avg(*a, &b)
    NoBrainer.run { self.without_ordering.to_rql.avg(*args_lookup_field_alias(a), &b) }
  end

  private

  def args_lookup_field_alias(a)
    a.map { |k| klass.lookup_field_alias(k) }
  end
end
