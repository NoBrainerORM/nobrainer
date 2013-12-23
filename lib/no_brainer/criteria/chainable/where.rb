module NoBrainer::Criteria::Chainable::Where
  extend ActiveSupport::Concern

  RESERVED_FIELDS = [:index, :default, :and, :or] + NoBrainer::DecoratedSymbol::MODIFIERS.keys

  included { attr_accessor :where_ast, :with_index_name }

  def initialize(options={})
    super
    self.where_ast = MultiOperator.new(:and, [])
  end

  def where(*args, &block)
    chain { |criteria| criteria.where_ast = parse_clause([*args, block].compact) }
  end

  def with_index(index_name)
    chain { |criteria| criteria.with_index_name = index_name }
  end

  def without_index
    with_index(false)
  end

  def used_index
    IndexFinder.new(compile_criteria).tap { |finder| finder.find_index }.index_name
  end

  def indexed?
    !!used_index
  end

  def merge!(criteria)
    super
    clauses = self.where_ast.clauses + criteria.where_ast.clauses
    self.where_ast = MultiOperator.new(:and, clauses).simplify
    self.with_index_name = criteria.with_index_name unless criteria.with_index_name.nil?
    self
  end

  private

  class MultiOperator < Struct.new(:op, :clauses)
    def simplify
      same_op_clauses, other_clauses = self.clauses.map(&:simplify)
        .partition { |v| v.is_a?(MultiOperator) && self.op == v.op }
      simplified_clauses = other_clauses + same_op_clauses.map(&:clauses).flatten(1)
      MultiOperator.new(op, simplified_clauses.uniq)
    end

    def to_rql(doc)
      case op
      when :and then clauses.map { |c| c.to_rql(doc) }.reduce { |a,b| a & b }
      when :or  then clauses.map { |c| c.to_rql(doc) }.reduce { |a,b| a | b }
      end
    end
  end

  class BinaryOperator < Struct.new(:key, :op, :value)
    def simplify
      self
    end

    def to_rql(doc)
      case op
      when :between then (doc[key] >= value.min) & (doc[key] <= value.max)
      when :in then value.map { |v| doc[key].eq(v) }.reduce { |a,b| a | b }
      else doc[key].__send__(op, value)
      end
    end
  end

  class UnaryOperator < Struct.new(:op, :value)
    def simplify
      value.is_a?(UnaryOperator) && [self.op, value.op] == [:not, :not] ? value.value : self
    end

    def to_rql(doc)
      case op
      when :not then value.to_rql(doc).not
      end
    end
  end

  class Lambda < Struct.new(:value)
    def simplify
      self
    end

    def to_rql(doc)
      value.call(doc)
    end
  end

  def parse_clause(clause)
    case clause
    when Array then MultiOperator.new(:and, clause.map { |c| parse_clause(c) })
    when Hash  then MultiOperator.new(:and, clause.map { |k,v| parse_clause_stub(k,v) })
    when Proc  then Lambda.new(clause)
    else raise "Invalid clause: #{clause}"
    end
  end

  def parse_clause_stub(key, value)
    case key
    when :and then MultiOperator.new(:and, value.map { |v| parse_clause(v) })
    when :or  then MultiOperator.new(:or,  value.map { |v| parse_clause(v) })
    when :not then UnaryOperator.new(:not, parse_clause(value))
    when String, Symbol then parse_clause_stub(key.to_sym.eq, value)
    when NoBrainer::DecoratedSymbol then
      case key.modifier
      when :ne then parse_clause(:not => { key.symbol => value })
      when :eq then
        case value
        when Range  then BinaryOperator.new(key.symbol, :between, value)
        when Regexp then BinaryOperator.new(key.symbol, :match, value.inspect[1..-2])
        else BinaryOperator.new(key.symbol, key.modifier, value)
        end
      else BinaryOperator.new(key.symbol, key.modifier, value)
      end
    else raise "Invalid key: #{key}"
    end
  end

  def without_index?
    self.with_index_name == false
  end

  class IndexFinder < Struct.new(:criteria, :index_name, :indexed_values, :ast)
    def get_candidate_clauses(*types)
      Hash[criteria.where_ast.clauses
        .select { |c| c.is_a?(BinaryOperator) && types.include?(c.op) }
        .map { |c| [c.key, c] }]
    end

    def get_usable_indexes(*types)
      indexes = criteria.klass.indexes
      indexes = indexes.select { |k,v| types.include?(v[:kind]) } if types.present?
      indexes = indexes.select { |k,v| k == criteria.with_index_name.to_sym } if criteria.with_index_name
      indexes
    end

    def find_index_canonical
      clauses = get_candidate_clauses(:eq, :in)
      return unless clauses.present?

      if index_name = (get_usable_indexes.keys & clauses.keys).first
        clause = clauses[index_name]
        self.index_name = index_name
        self.indexed_values = clause.op == :in ? clause.value : [clause.value]
        self.ast = MultiOperator.new(:and, criteria.where_ast.clauses - [clause])
      end
    end

    def find_index_compound
      clauses = get_candidate_clauses(:eq)
      return unless clauses.present?

      index_name, index_values = get_usable_indexes(:compound)
        .map    { |name, option| [name, option[:what]] }
        .select { |name, values| values & clauses.keys == values }
        .first

      if index_name
        indexed_clauses = index_values.map { |field| clauses[field] }
        self.index_name = index_name
        self.indexed_values = [indexed_clauses.map { |c| c.value }]
        self.ast = MultiOperator.new(:and, criteria.where_ast.clauses - indexed_clauses)
      end
    end

    def find_index
      return false if criteria.__send__(:without_index?)
      could_find_index = find_index_canonical || find_index_compound
      if criteria.with_index_name && !could_find_index
        raise NoBrainer::Error::CannotUseIndex.new("Cannot use index #{criteria.with_index_name}")
      end
      !!could_find_index
    end
  end

  def compile_rql
    rql = super
    ast = self.where_ast
    finder = IndexFinder.new(self)
    if finder.find_index
      ast = finder.ast
      rql = rql.get_all(*finder.indexed_values, :index => finder.index_name)
    end
    rql = rql.filter { |doc| ast.to_rql(doc) } if ast.clauses.present?
    rql
  end
end
