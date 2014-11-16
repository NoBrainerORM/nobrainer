module NoBrainer::Criteria::OrderBy
  extend ActiveSupport::Concern

  # The latest order_by() wins
  included { criteria_option :order_by, :ordering_mode, :merge_with => :set_scalar }

  def order_by(*rules, &block)
    # Note: We are relying on the fact that Hashes are ordered (since 1.9)
    rules = [*rules, block].flatten.compact.map do |rule|
      case rule
      when Hash then
        bad_rule = rule.values.reject { |v| v.in? [:asc, :desc] }.first
        raise_bad_rule(bad_rule) if bad_rule
        rule
      when String, Symbol, Proc then { rule => :asc }
      else raise_bad_rule(rule)
      end
    end.reduce({}, :merge)

    chain(:order_by => rules, :ordering_mode => :normal)
  end

  def without_ordering
    chain(:ordering_mode => :disabled)
  end

  def reverse_order
    chain(:ordering_mode => case @options[:ordering_mode]
                            when nil       then :reversed
                            when :normal   then :reversed
                            when :reversed then :normal
                            when :disabled then :disabled
                            end)
  end

  def order_by_indexed?
    !!order_by_index_name
  end

  def order_by_index_name
    order_by_index_finder.index_name
  end

  private

  def effective_order
    @options[:order_by].presence || (model ? {model.pk_name => :asc} : {})
  end

  def reverse_order?
    @options[:ordering_mode] == :reversed
  end

  def should_order?
    @options[:ordering_mode] != :disabled
  end

  class IndexFinder < Struct.new(:criteria, :index_name, :rql_proc)
    def could_find_index?
      !!self.index_name
    end

    def first_key
      @first_key ||= criteria.__send__(:effective_order).first.try(:[], 0)
    end

    def first_key_indexable?
      return false unless first_key.is_a?(Symbol) || first_key.is_a?(String)
      return false unless index = criteria.model.indexes[first_key.to_sym]
      return !index.multi && !index.geo
    end

    def find_index
      return if criteria.without_index?
      return unless first_key_indexable?

      if criteria.options[:use_index] && criteria.options[:use_index] != true
        return unless first_key.to_s == criteria.options[:use_index].to_s
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
    @order_by_index_finder ||= IndexFinder.new(self).tap(&:find_index)
  end

  def compile_rql_pass1
    rql = super
    return rql unless should_order?
    _effective_order = effective_order
    return rql if _effective_order.empty?

    rql_rules = _effective_order.map do |k,v|
      if order_by_index_finder.index_name == k
        k = model.lookup_index_alias(k)
      else
        k = model.lookup_field_alias(k)
      end

      case v
      when :asc  then reverse_order? ? RethinkDB::RQL.new.desc(k) : RethinkDB::RQL.new.asc(k)
      when :desc then reverse_order? ? RethinkDB::RQL.new.asc(k)  : RethinkDB::RQL.new.desc(k)
      end
    end

    # We can only apply an indexed order_by on a table() RQL term.
    # If we can, great. Otherwise, the ordering is applied in pass2, which will
    # happen after a potential filter(), which is better for perfs.
    if order_by_index_finder.could_find_index?
      options = { :index => rql_rules.shift }
      rql = rql.order_by(*rql_rules, options)
    else
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
