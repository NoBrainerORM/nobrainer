module NoBrainer::Selection::Inc
  def inc(field, value=1)
    # TODO The useful inc() is on a model instance.
    # But then do we want to postpone the inc() to the next save?
    # It might make sense (because we don't have transactions).
    update { |doc| { field => doc[field] + value } }
  end

  def dec(field, value=1)
    inc(field, -value)
  end
end
