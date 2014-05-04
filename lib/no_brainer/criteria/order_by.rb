module NoBrainer::Criteria::OrderBy
  extend ActiveSupport::Concern

  included { attr_accessor :order, :ordering_mode }

  def initialize(options={})
    super
    self.order = {}
  end

  def order_by(*rules, &block)
    # Note: We are relying on the fact that Hashes are ordered (since 1.9)
    rules = [*rules, block].compact.map do |rule|
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
      criteria.ordering_mode = :normal
    end
  end

  def without_ordering
    chain { |criteria| criteria.ordering_mode = :disabled }
  end

  def merge!(criteria, options={})
    super
    # The latest order_by() wins
    self.order = criteria.order if criteria.order.present?
    self.ordering_mode = criteria.ordering_mode unless criteria.ordering_mode.nil?
    self
  end

  def reverse_order
    chain do |criteria|
      criteria.ordering_mode =
        case self.ordering_mode
        when nil       then :reversed
        when :normal   then :reversed
        when :reversed then :normal
        when :disabled then :disabled
        end
    end
  end

  private

  def effective_order
    self.order.presence || {:id => :asc}
  end

  def reverse_order?
    self.ordering_mode == :reversed
  end

  def should_order?
    self.ordering_mode != :disabled
  end

  def compile_rql_pass1
    rql = super
    return rql unless should_order?

    rql_rules = effective_order.map do |k,v|
      case v
      when :asc  then reverse_order? ? RethinkDB::RQL.new.desc(k) : RethinkDB::RQL.new.asc(k)
      when :desc then reverse_order? ? RethinkDB::RQL.new.asc(k)  : RethinkDB::RQL.new.desc(k)
      end
    end

    # We can only apply an index order_by on a table() term.
    # We are going to try to go so and if we cannot, we'll simply apply
    # the ordering in pass2, which will happen after a potential filter().

    NoBrainer::RQL.is_table?(rql)
    if NoBrainer::RQL.is_table?(rql) && !without_index?
      options = {}
      first_key = effective_order.first[0]
      if (first_key.is_a?(Symbol) || first_key.is_a?(String)) && klass.has_index?(first_key)
        options[:index] = rql_rules.shift
      end

      rql = rql.order_by(*rql_rules, options)
    else
      # Stashing @rql_rules for pass2, which is a pretty gross hack.
      # We should really use more of a middleware pattern to build the RQL.
      @rql_rules_pass2 = rql_rules
    end

    rql
  end

  def compile_rql_pass2
    rql = super
    if @rql_rules_pass2
      rql = rql.order_by(*@rql_rules_pass2)
      @rql_rules_pass2 = nil
    end
    rql
  end

  def raise_bad_rule(rule)
    raise "Please pass something like ':field1 => :desc, :field2 => :asc', not #{rule}"
  end
end
