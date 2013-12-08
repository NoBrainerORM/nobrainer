module NoBrainer::Selection::OrderBy
  def order_by(*rules)
    # Note: We are relying on the fact that Hashes are ordered (since 1.9)
    rules = rules.map do |rule|
      case rule
      when Hash   then rule
      when Symbol then { rule => :asc }
      else raise "please pass symbols, or hashes, not #{rule}"
      end
    end.reduce(:merge)

    build_query(rules)
  end

  def reverse_order
    raise "No ordering set" unless context[:order]

    rules = context[:order].map do |k,v|
      v == :asc ? { k => :desc } : { k => :asc }
    end.reduce(:merge)

    # This is a bit gross, because we still have the original ordering in the
    # query, we are just putting a new ordering on top of it.
    # TODO we might have to compile queries properly :)

    build_query(rules)
  end

  def ordered?
    !!context[:order]
  end

  private

  def build_query(rules)
    rql_rules = rules.map do |k,v|
      case v
      when :asc  then RethinkDB::RQL.new.asc(k)
      when :desc then RethinkDB::RQL.new.desc(k)
      else raise "please pass :asc or :desc, not #{v}"
      end
    end

    chain(query.order_by(*rql_rules), context.deep_merge(:order => rules))
  end
end
