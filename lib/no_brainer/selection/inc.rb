module NoBrainer::Selection::Inc
  def inc(field, value=1)
    # TODO return the new value
    update { |doc| { field => doc[field] + value } }
  end

  def dec(field, value=1)
    inc(field, -value)
  end
end
