module NoBrainer::Selection::Where
  def where(*args, &block)
    options = args.extract_options!.dup
    regexp_filters = extract_regexp!(options)
    default_option = options.select { |k,v| k == :default }

    filtered_query = query.filter(*args, options, &block)

    if !regexp_filters.empty?
      filtered_query = filtered_query.filter(default_option) do |doc|
        regexp_filters.map    { |field, regexp| doc[field].match(regexp) }
                      .reduce { |a,b| a & b }
      end
    end

    chain filtered_query
  end

  private

  def extract_regexp!(options)
    regexp_filters = {}
    options.each do |k,v|
      if v.is_a?(Regexp)
        options.delete(k)
        regexp_filters[k] = v.inspect[1..-2]
      end
    end
    regexp_filters
  end
end
