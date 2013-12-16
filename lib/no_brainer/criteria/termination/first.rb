module NoBrainer::Criteria::Termination::First
  def first
    get_one(ordered? ? self : order_by(:id => :asc))
  end

  def last
    get_one(ordered? ? self.reverse_order : order_by(:id => :desc))
  end

  private

  def get_one(criteria)
    attrs = criteria.limit(1).run.first
    klass.new_from_db(attrs)
  end
end
