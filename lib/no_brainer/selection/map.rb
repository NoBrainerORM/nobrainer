module NoBrainer::Selection::Map
  def map(&block)
    chain query.map(&block)
  end
end
