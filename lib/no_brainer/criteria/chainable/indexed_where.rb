module NoBrainer::Criteria::Chainable::IndexedWhere
  extend ActiveSupport::Concern

  included { attr_accessor :index_clause, :_without_index }

  def indexed_where(attr)
    raise "Use :index_name => value" unless attr.is_a?(Hash)
    raise "Cannot use two indexes" unless attr.size == 1
    chain { |criteria| criteria.index_clause = attr }
  end

  def merge!(criteria)
    super
    if self.index_clause != criteria.index_clause
      raise "Cannot use two indexes" if indexed?
      self.index_clause = criteria.index_clause
    end
    self._without_index = criteria._without_index unless criteria._without_index.nil?
  end

  def indexed?
    !!self.index_clause
  end

  def without_index
    chain { |criteria| criteria._without_index = true }
  end

  def without_index?
    # Used by where() to prevent automatic index usage
    !!self._without_index
  end

  def compile_rql
    rql = super
    rql = rql.get_all(index_clause.first[1], :index => index_clause.first[0]) if index_clause
    rql
  end

  def compile_criteria_pass2
    # The point of this method is to pick an index instead of using a filter.
    # The whole thing is a performance optimization, and could be commented out.
    return super unless self.where_clauses.present? && klass.indexes.present? &&
                        !indexed? && !without_index?

    # The following tries to extract from all the where clauses the filters that
    # could be used with an index.
    wc_hash = []; wc_eq_hash = {}; wc_others = []
    self.where_clauses.each { |wc| (wc.is_a?(Hash) ? wc_hash : wc_others) << wc }
    wc_hash.reduce(:merge).each do |k,v|
      if k.to_sym.in?(NoBrainer::Criteria::Chainable::Where::RESERVED_FIELDS) ||
         k.is_a?(NoBrainer::DecoratedSymbol) ||
         v.is_a?(Regexp) || v.is_a?(Range)
        wc_others << {k => v}
      else
        wc_eq_hash[k.to_sym] = v
      end
    end

    query_keys = wc_eq_hash.keys.map(&:to_sym)

    # We want to use an index that have the most number of fields in it
    index_keys, index_name = klass.indexes
      .map { |name, args| [[*args[:what]], name] }
      .sort_by! { |k,v| -k.size }
      .select { |k,v| k & query_keys == k}
      .first

    criteria = super
    if index_name
      wc_hash_others = wc_eq_hash.reject { |k,v| k.in?(index_keys) }
      wc_others << wc_hash_others if wc_hash_others.present?

      value = index_keys.map { |k| wc_eq_hash[k] }
      value = value.first if klass.indexes[index_name][:kind] == :single
      criteria = criteria.indexed_where(index_name => value)
      criteria.where_clauses = wc_others
    end
    criteria
  end
end
