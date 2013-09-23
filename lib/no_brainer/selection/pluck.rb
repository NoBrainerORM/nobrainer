module NoBrainer::Selection::Pluck
  def pluck(*args)
    chain(query.pluck(*args)).run
  end
end