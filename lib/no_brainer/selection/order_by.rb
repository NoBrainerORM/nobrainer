module NoBrainer::Selection::OrderBy
  def order_by(*rules)
    if rules[0].is_a? Hash
      # Exploiting the fact that Hashes are now ordered.
      # XXX TODO Throw an exception when using ruby 1.8
      rules = rules[0].map do |k,v|
        case v
        when :asc  then [k, true]
        when :desc then [k, false]
        else raise "please pass :asc or :desc, not #{v}"
        end
      end
    end

    chain(query.order_by(*rules), context.merge(:ordered => true))
  end

  def ordered?
    !!context[:ordered]
  end
end
