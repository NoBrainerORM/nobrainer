module NoBrainer::Selection::OrderBy
  def order_by(*rules)
    rule = rules[0]
    if rule.is_a? Hash
      # Exploiting the fact that Hashes are now ordered
      rules = rule.map do |key,value|
        case value
        when :asc  then RethinkDB::RQL.new.asc(key)
        when :desc then RethinkDB::RQL.new.desc(key)
        else raise "please pass :asc or :desc, not #{value}"
        end
      end
    end

    chain(query.order_by(*rules), context.merge(:ordered => true))
  end

  def ordered?
    !!context[:ordered]
  end
end
