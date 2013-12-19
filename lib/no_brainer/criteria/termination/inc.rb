module NoBrainer::Criteria::Termination::Inc
  def inc_all(field, value=1)
    # TODO The useful inc() is on a model instance.
    # But then do we want to postpone the inc() to the next save?
    # It might make sense (because we don't have transactions).
    update_all { |doc| { field => doc[field] + value } }
  end

  def dec_all(field, value=1)
    inc_all(field, -value)
  end
end
