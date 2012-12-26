module NoBrainer::Selection::Where
  def filter(*args, &block)
    chain query.filter(*args, &block)
  end

  def where(attrs)
    return self if attrs.empty?

    # Waiting for https://github.com/rethinkdb/rethinkdb/issues/183
    # For now, we require all the fields to be matched to be present
    # in the documents.
    # This means that where(:non_existing => nil) will never match anything.
    filter do |doc|
      attrs.map    { |k,v| doc.contains(k) & doc[k].eq(v) }
           .reduce { |a,b| a & b }
    end
  end
end
