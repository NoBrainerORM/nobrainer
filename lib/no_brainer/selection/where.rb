module NoBrainer::Selection::Where
  def filter(*args, &block)
    chain query.filter(*args, &block)
  end

  alias where filter
end
