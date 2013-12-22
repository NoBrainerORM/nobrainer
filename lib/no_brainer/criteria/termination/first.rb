module NoBrainer::Criteria::Termination::First
  extend ActiveSupport::Concern

  def first(options={})
    return get_one(self, options)
  end

  def last(options={})
    return get_one(self.reverse_order, options)
  end

  private

  def get_one(criteria, options={})
    attrs = criteria.limit(1).run.first
    options[:raw] ? attrs : klass.new_from_db(attrs)
  end
end
