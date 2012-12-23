class NoBrainer::Selection
  attr_accessor :query, :klass

  def initialize(query, klass)
    self.query = query
    self.klass = klass
  end

  def chain(query)
    self.class.new(query, klass)
  end

  [:filter, :skip, :limit].each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}(*args, &block)
        chain query.#{method}(*args, &block)
      end
    RUBY
  end

  alias_method :where, :filter

  # @rules can be {:field1 => :asc, :field2 => :desc}
  # XXX This only make sense because we have ordered hashes since 1.9.3
  # But is it true for other interpreters?
  def order_by(rules)
    rules = rules.map do |k,v|
      case v
      when :asc  then [k, true]
      when :desc then [k, false]
      else raise "please pass :asc or :desc, not #{v}"
      end
    end
    chain query.order_by(*rules)
  end

  def first(order = :asc)
    klass.ensure_table! # needed as soon as we get a Query_Result
    # TODO FIXME are not sequential, how do we do that ?? :(
    attrs = NoBrainer.run { order_by(:id => order).limit(1) }.first
    klass.from_attributes(attrs)
  end

  def last
    first(:desc)
  end

  def count
    NoBrainer.run { chain query.count }
  end

  def inspect
    query.inspect.gsub(/^db\(:default_db\)./, '')
  end
end
