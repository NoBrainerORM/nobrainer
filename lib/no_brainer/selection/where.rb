module NoBrainer::Selection::Where
  def filter(*args, &block)
    filtered = nil
    options = args.last
    options.each do |key, value|
      if value.is_a?(Regexp)
        value = options.delete(key)
        filtered = match(key, value).filter(options)
      end
    end if options
    chain (filtered || query).filter(*args, &block)
  end
  alias where filter

  def match(field, regex)
    regex_string = regex.inspect[1..-2]
    chain query.filter { |row| row[field].match(regex_string) }
  end
end
