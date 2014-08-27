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
      when String, Symbol, Proc then { rule => :asc }
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

  def order_by_indexed?
    !!order_by_index_name
  end

  def order_by_index_name
    order_by_index_finder.index_name
  end

  private

  def effective_order
    self.order.presence || (klass ? {klass.pk_name => :asc} : {})
  end

  def reverse_order?
    self.ordering_mode == :reversed
  end

  def should_order?
    self.ordering_mode != :disabled
  end

  class IndexFinder < Struct.new(:criteria, :index_name, :rql_proc)
    def could_find_index?
      !!self.index_name
    end

    def first_key
      @first_key ||= criteria.__send__(:effective_order).first.try(:[], 0)
    end

    def first_key_indexable?
      (first_key.is_a?(Symbol) || first_key.is_a?(String)) && criteria.klass.has_index?(first_key)
    end

    def find_index
      return if criteria.without_index?
      return unless first_key_indexable?

      if criteria.with_index_name && criteria.with_index_name != true
        return unless first_key.to_s == criteria.with_index_name.to_s
      end

      # We need make sure that the where index finder has been invoked, it has priority.
      # If it doesn't find anything, we are free to go with our indexes.
      if !criteria.where_indexed? || (criteria.where_index_type == :between &&
                                      first_key.to_s == criteria.where_index_name.to_s)
        self.index_name = first_key
      end
    end
  end

  def order_by_index_finder
    return finalized_criteria.__send__(:order_by_index_finder) unless finalized?
    @order_by_index_finder ||= IndexFinder.new(self).tap { |index_finder| index_finder.find_index }
  end

  def compile_rql_pass1
    rql = super
    return rql unless should_order?
    _effective_order = effective_order
    return rql if _effective_order.empty?

    rql_rules = _effective_order.map do |k,v|
      if order_by_index_finder.index_name == k
        k = klass.lookup_index_alias(k)
      else
        k = klass.lookup_field_alias(k)
      end

      case v
      when :asc  then reverse_order? ? RethinkDB::RQL.new.desc(k) : RethinkDB::RQL.new.asc(k)
      when :desc then reverse_order? ? RethinkDB::RQL.new.asc(k)  : RethinkDB::RQL.new.desc(k)
      end
    end

    # We can only apply an index order_by on a table() term.
    # We are going to try to go so and if we cannot, we'll simply apply
    # the ordering in pass2, which will happen after a potential filter().
    if order_by_index_finder.could_find_index?
      options = { :index => rql_rules.shift }
      rql = rql.order_by(*rql_rules, options)
    else
      # Stashing @rql_rules for pass2
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
