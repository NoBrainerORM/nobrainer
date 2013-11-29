module NoBrainer::Selection::Where
  def where(*args, &block)
    options, default_option, regexp_filters =
      extract_options_and_regexp_filters(args)

    filtered_query = query.filter(*args, options, &block)
    filtered_query = where_module.
      apply_regexp_filters!(filtered_query, default_option, regexp_filters)


    chain filtered_query
  end

  private
  def where_module
    NoBrainer::Selection::Where
  end

  def extract_options_and_regexp_filters(args)
    options = args.extract_options!.dup
    regexp_filters = where_module.extract_regexp!(options)
    default_option = options.select {|key, value| key == :default}
    [options, default_option, regexp_filters]
  end

  def self.extract_regexp!(options)
    regexp_filters = {}
    options.each do |key, value|
      if value.is_a?(Regexp)
        options.delete(key)
        regexp_filters[key] = value.inspect[1..-2]
      end
    end
    regexp_filters
  end

  def self.apply_regexp_filters!(query, default_option, regexp_filters)
    unless regexp_filters.empty?
      query = query.filter(default_option) do |doc|
        map_and_reduce_regexp_filters(regexp_filters, doc)
      end
    end
    query
  end

  def self.map_and_reduce_regexp_filters(regexp_filters, doc)
    regexp_filters.
      map {|field, regexp| doc[field].match(regexp)}.
      reduce {|alpha, beta| alpha & beta}
  end
end
