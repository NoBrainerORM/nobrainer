module NoBrainer::Criteria::Chainable::OrderBy
  extend ActiveSupport::Concern

  included { attr_accessor :order }

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
      else raise_bad_rule(rule)
      end
    end.reduce(:merge)

    chain { |criteria| criteria.order = rules }
  end

  def merge!(criteria)
    super
    # Being careful to keep the original order, and appending the new
    # rules at the end.
    self.order.reject! { |k,v| k.in? criteria.order.keys }
    self.order.merge! criteria.order
  end

  def reverse_order
    raise "No ordering set" unless ordered?

    rules = self.order.map do |k,v|
      v == :asc ? { k => :desc } : { k => :asc }
    end.reduce(:merge)

    chain { |criteria| criteria.order = rules }
  end

  def ordered?
    self.order.present?
  end

  def compile_rql
    rql = super
    if self.ordered?
      rql_rules = self.order.map do |k,v|
        case v
        when :asc  then RethinkDB::RQL.new.asc(k)
        when :desc then RethinkDB::RQL.new.desc(k)
        end
      end
      rql = rql.order_by(*rql_rules)
    end
    rql
  end

  def raise_bad_rule(rule)
    raise "Please pass something like ':field1=> :desc, :field2 => :asc', not #{rule}"
  end
end
