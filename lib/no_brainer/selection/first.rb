module NoBrainer::Selection::First
  def first
    get_one(ordered? ? self : order_by(:id => :asc))
  end

  def last
    get_one(ordered? ? self.reverse_order : order_by(:id => :desc))
  end

  private

  def get_one(selection)
    klass.ensure_table! # needed as soon as we get a Query_Result
    attrs = selection.limit(1).run.first
    klass.new_from_db(attrs)
  end
end
