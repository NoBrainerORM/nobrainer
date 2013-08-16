module NoBrainer::Selection::Where
  def filter(*args, &block)
    chain query.filter(*args, &block)
  end

  def where(attrs={}, &block)
    sel = self

    if attrs.present?
      # Waiting for https://github.com/rethinkdb/rethinkdb/issues/183
      # For now, we require all the fields to be matched to be present
      # in the documents.
      # This means that where(:non_existing => nil) will never match anything.
      sel = filter do |doc|
        attrs.map    { |k,v| doc.has_fields(k) & doc[k].eq(v) }
             .reduce { |a,b| a & b }
      end
    end

    sel = filter(&block) if block
    sel
  end
end
