module NoBrainer::Criteria::Chainable::Where
  extend ActiveSupport::Concern

  RESERVED_FIELDS = NoBrainer::DecoratedSymbol::MODIFIERS.keys + [:default, :and, :or]

  included { attr_accessor :where_clauses }

  def initialize(options={})
    super
    self.where_clauses = []
  end

  def where(*args, &block)
    chain { |criteria| criteria.where_clauses = [*args, block].compact }
  end

  def merge!(criteria)
    super
    self.where_clauses += criteria.where_clauses
  end

  def compile_rql
    return super unless self.where_clauses.present?

    # TODO Primary key might not always be id
    if where_clauses.size == 1
      wc = where_clauses.first
      if wc.is_a?(Hash) && wc.size == 1 && wc.keys.first == :id
        return super.get(wc.values.first)
      end
    end

    super.filter { |doc| normalize_filters(doc, self.where_clauses) || {} }
  end

  def normalize_filters(doc, filter)
    case filter
    when Array then normalize_filters(doc, :and => filter)
    when Proc  then filter.call(doc)
    when Hash
      case filter.size
      when 0 then nil
      when 1 then normalize_filter_stub(doc, filter.first[0], filter.first[1])
      else normalize_filters(doc, :and => filter.map { |k,v| { k => v } })
      end
    else raise "Invalid filter: #{filter}"
    end
  end

  def normalize_filter_stub(doc, field, value)
    case field
    when :and then value.map { |v| normalize_filters(doc, v) }.compact.reduce { |a,b| a & b }
    when :or  then value.map { |v| normalize_filters(doc, v) }.compact.reduce { |a,b| a | b }
    when NoBrainer::DecoratedSymbol then
      case field.modifier
      when :not then normalize_filters(doc, field.symbol => value).not
      when :in  then normalize_filters(doc, :or => value.map { |v| { field.symbol => v } })
      else doc[field.symbol].__send__(field.modifier, value)
      end
    else
      case value
      when Range  then (doc[field] >= value.min) & (doc[field] <= value.max)
      when Regexp then doc[field].match(value.inspect[1..-2])
      else doc[field].eq(value)
      end
    end
  end
end
