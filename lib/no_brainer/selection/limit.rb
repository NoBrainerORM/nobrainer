module NoBrainer::Selection::Limit
  # TODO Test these guys

  def limit(value)
    chain query.limit(value)
  end

  def skip(value)
    chain query.skip(value)
  end

  def [](sel)
    chain query[sel]
  end
end
