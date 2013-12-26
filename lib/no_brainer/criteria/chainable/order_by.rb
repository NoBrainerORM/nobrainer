module NoBrainer::Criteria::Chainable::OrderBy
  extend ActiveSupport::Concern

  included { attr_accessor :order, :_reverse_order }

  def initialize(options={})
    super
    self.order = {}
  end

  def order_by(*rules)
    # Note: We are relying on the fact that Hashes are ordered (since 1.9)
    rules = rules.map do |rule|
      case rule
      when Hash then
        bad_rule = rule.values.reject { |v| v.in? [:asc, :desc] }.first
        raise_bad_rule(bad_rule) if bad_rule
        rule
      when Symbol then { rule => :asc }
      when Proc   then { rule => :asc }
      else raise_bad_rule(rule)
      end
    end.reduce({}, :merge)

    chain do |criteria|
      criteria.order = rules
      criteria._reverse_order = false
    end
  end

  def merge!(criteria)
    super
    # The latest wins
    self.order = criteria.order if criteria.order.present?
    self._reverse_order = criteria._reverse_order unless criteria._reverse_order.nil?
    self
  end

  def reverse_order
    chain { |criteria| criteria._reverse_order = !self._reverse_order }
  end

  private

  def effective_order
    self.order.present? ? self.order : {:id => :asc}
  end

  def reverse_order?
    !!self._reverse_order
  end

  def compile_rql
    rql_rules = effective_order.map do |k,v|
      case v
      when :asc  then reverse_order? ? RethinkDB::RQL.new.desc(k) : RethinkDB::RQL.new.asc(k)
      when :desc then reverse_order? ? RethinkDB::RQL.new.asc(k)  : RethinkDB::RQL.new.desc(k)
      end
    end

    options = {}
    unless without_index?
      first_key = effective_order.first[0]
      first_key = nil if first_key == :id # FIXME For some reason, using the id index doesn't work.
      if (first_key.is_a?(Symbol) || first_key.is_a?(String)) && klass.has_index?(first_key)
        options[:index] = rql_rules.shift
      end
    end

    super.order_by(*rql_rules, options)
  end

  def raise_bad_rule(rule)
    raise "Please pass something like ':field1 => :desc, :field2 => :asc', not #{rule}"
  end
end
