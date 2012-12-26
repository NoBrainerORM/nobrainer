module NoBrainer::Selection::Count
  def count
    chain(query.count).run
  end

  def empty?
    count == 0
  end

  def any?
    !empty?
  end
end
