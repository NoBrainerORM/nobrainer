module NoBrainer::Selection::Count
  def count
    chain(query.count).run
  end

  def empty?
    count == 0
  end

  def any?
    if block_given?
      to_a.any? { |*args| yield(*args) }
    else
      !empty?
    end
  end
end
