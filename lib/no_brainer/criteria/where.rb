module NoBrainer::Criteria::Where
  extend ActiveSupport::Concern

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
    index_finder.index_name
  end

  def indexed?
    index_finder.could_find_index?
  end

  def merge!(criteria, options={})
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

  class BinaryOperator < Struct.new(:key, :op, :value, :criteria)
    def simplify
      key = cast_key(self.key)
      case op
      when :in then
        case value
        when Range then BinaryOperator.new(key, :between, (cast_value(value.min)..cast_value(value.max)), criteria)
        when Array then BinaryOperator.new(key, :in, value.map(&method(:cast_value)).uniq, criteria)
        else raise ArgumentError.new ":in takes an array/range, not #{value}"
        end
      when :between then BinaryOperator.new(key, :between, (cast_value(value.min)..cast_value(value.max)), criteria)
      else BinaryOperator.new(key, op, cast_value(value), criteria)
      end
    end

    def to_rql(doc)
      case op
      when :defined then value ? doc.has_fields(key) : doc.has_fields(key).not
      when :between then (doc[key] >= value.min) & (doc[key] <= value.max)
      when :in      then RethinkDB::RQL.new.expr(value).contains(doc[key])
      else doc[key].__send__(op, value)
      end
    end

    private

    def association
      # FIXME This leaks memory with dynamic attributes. The internals of type
      # checking will convert the key to a symbol, and Ruby does not garbage
      # collect symbols.
      @association ||= [criteria.klass.association_metadata[key.to_sym]]
      @association.first
    end

    def cast_value(value)
      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata
        target_klass = association.target_klass
        opts = { :attr_name => key, :value => value, :type => target_klass}
        raise NoBrainer::Error::InvalidType.new(opts) unless value.is_a?(target_klass)
        value.pk_value
      else
        criteria.klass.safe_cast_user_to_db_for(key, value)
      end
    end

    def cast_key(key)
      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata
        association.foreign_key
      else
        key
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
    when NoBrainer::DecoratedSymbol
      case clause.args.size
      when 1 then parse_clause_stub(clause, clause.args.first)
      else raise "Invalid argument: #{clause}"
      end
    else raise "Invalid clause: #{clause}"
    end
  end

  def parse_clause_stub(key, value)
    case key
    when :and then MultiOperator.new(:and, value.map { |v| parse_clause(v) })
    when :or  then MultiOperator.new(:or,  value.map { |v| parse_clause(v) })
    when :not then UnaryOperator.new(:not, parse_clause(value))
    when String, Symbol then parse_clause_stub_eq(key, value)
    when NoBrainer::DecoratedSymbol then
      case key.modifier
      when :nin then parse_clause(:not => { key.symbol.in => value })
      when :ne  then parse_clause(:not => { key.symbol.eq => value })
      when :eq  then parse_clause_stub_eq(key.symbol, value)
      else BinaryOperator.new(key.symbol, key.modifier, value, self)
      end
    else raise "Invalid key: #{key}"
    end
  end

  def parse_clause_stub_eq(key, value)
    case value
    when Range  then BinaryOperator.new(key, :between, value, self)
    when Regexp then BinaryOperator.new(key, :match, value.inspect[1..-2], self)
    else BinaryOperator.new(key, :eq, value, self)
    end
  end

  def without_index?
    self.with_index_name == false
  end

  class IndexFinder < Struct.new(:criteria, :index_name, :rql_proc, :ast)
    def initialize(*args)
      super
      find_index
    end

    def could_find_index?
      !!self.index_name
    end

    private

    def get_candidate_clauses(*types)
      criteria.where_ast.clauses.select { |c| c.is_a?(BinaryOperator) && types.include?(c.op) }
    end

    def get_usable_indexes(*types)
      indexes = criteria.klass.indexes
      indexes = indexes.select { |k,v| types.include?(v[:kind]) } if types.present?
      indexes = indexes.select { |k,v| k == criteria.with_index_name.to_sym } if criteria.with_index_name
      indexes
    end

    def find_index_canonical
      clauses = Hash[get_candidate_clauses(:eq, :in, :between).map { |c| [c.key, c] }]
      return unless clauses.present?

      if index_name = (get_usable_indexes.keys & clauses.keys).first
        clause = clauses[index_name]
        self.index_name = index_name
        self.ast = MultiOperator.new(:and, criteria.where_ast.clauses - [clause])
        self.rql_proc = case clause.op
          when :eq      then ->(rql){ rql.get_all(clause.value, :index => index_name) }
          when :in      then ->(rql){ rql.get_all(*clause.value, :index => index_name) }
          when :between then ->(rql){ rql.between(clause.value.min, clause.value.max, :index => index_name,
                                                  :left_bound => :closed, :right_bound => :closed) }
        end
      end
    end

    def find_index_compound
      clauses = Hash[get_candidate_clauses(:eq).map { |c| [c.key, c] }]
      return unless clauses.present?

      index_name, index_values = get_usable_indexes(:compound)
        .map    { |name, option| [name, option[:what]] }
        .select { |name, values| values & clauses.keys == values }
        .first

      if index_name
        indexed_clauses = index_values.map { |field| clauses[field] }
        self.index_name = index_name
        self.ast = MultiOperator.new(:and, criteria.where_ast.clauses - indexed_clauses)
        self.rql_proc = ->(rql){ rql.get_all(indexed_clauses.map { |c| c.value }, :index => index_name) }
      end
    end

    def find_index_hidden_between
      clauses = get_candidate_clauses(:gt, :ge, :lt, :le).group_by(&:key)
      return unless clauses.present?

      if index_name = (get_usable_indexes.keys & clauses.keys).first
        op_clauses = Hash[clauses[index_name].map { |c| [c.op, c] }]
        left_bound = op_clauses[:gt] || op_clauses[:ge]
        right_bound = op_clauses[:lt] || op_clauses[:le]

        self.index_name = index_name
        self.ast = MultiOperator.new(:and, criteria.where_ast.clauses - [left_bound, right_bound].compact)

        options = {:index => index_name}
        options[:left_bound]  = {:gt => :open, :ge => :closed}[left_bound.op] if left_bound
        options[:right_bound] = {:lt => :open, :le => :closed}[right_bound.op] if right_bound
        self.rql_proc = ->(rql){ rql.between(left_bound.try(:value), right_bound.try(:value), options) }
      end
    end

    def find_index
      return if criteria.__send__(:without_index?)
      find_index_canonical || find_index_compound || find_index_hidden_between
      if criteria.with_index_name && !could_find_index?
        raise NoBrainer::Error::CannotUseIndex.new("Cannot use index #{criteria.with_index_name}")
      end
    end
  end

  def index_finder
    return with_default_scope_applied.__send__(:index_finder) if should_apply_default_scope?
    @index_finder ||= IndexFinder.new(self)
  end

  def compile_rql_pass1
    rql = super
    rql = index_finder.rql_proc.call(rql) if index_finder.could_find_index?
    rql
  end

  def compile_rql_pass2
    rql = super
    ast = index_finder.could_find_index? ? index_finder.ast : self.where_ast
    rql = rql.filter { |doc| ast.to_rql(doc) } if ast.clauses.present?
    rql
  end
end
