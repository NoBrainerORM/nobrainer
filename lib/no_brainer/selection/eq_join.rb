module NoBrainer::Selection::EqJoin
  def eq_join(*args, &block)
    chain query.eq_join(*args, &block)
  end

end
