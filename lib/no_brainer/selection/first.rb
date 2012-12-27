module NoBrainer::Selection::First
  def first
    get_one(:asc)
  end

  def last
    raise 'last does not work with a custom ordering. ' +
          'please fix and Make a pull request' if ordered?
    get_one(:desc)
  end

  private

  def get_one(order)
    klass.ensure_table! # needed as soon as we get a Query_Result

    sel = ordered? ? self : order_by(:id => order)
    attrs = sel.limit(1).run.first
    klass.new_from_db(attrs)
  end
end
