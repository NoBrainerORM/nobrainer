module NoBrainer::Selection::Enumerable
  def each(&block)
    return enum_for(:each) unless block

    klass.ensure_table! # needed as soon as we get a Query_Result
    run.each do |attrs|
      yield klass.new_from_db(attrs)
    end
    self
  end

  def method_missing(name, *args, &block)
    each.__send__(name, *args, &block)
  end
end
