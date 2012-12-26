module NoBrainer::Selection::First
  def first(order = :asc)
    klass.ensure_table! # needed as soon as we get a Query_Result
    # TODO FIXME do not add an order_by if there is already one
    attrs = order_by(:id => order).limit(1).run.first
    klass.new_from_db(attrs)
  end

  def last
    first(:desc)
  end
end
