module NoBrainer::Criteria::Where
  extend ActiveSupport::Concern

  included { attr_accessor :where_ast, :with_index_name }

  def initialize(options={})
    super
  end

  def where(*args, &block)
    chain { |criteria| criteria.where_ast = parse_clause([*args, block].compact) }
  end

  def merge!(criteria, options={})
    super

    if criteria.where_ast
      if self.where_ast
        self.where_ast = MultiOperator.new(:and, [self.where_ast, criteria.where_ast])
      else
        self.where_ast = criteria.where_ast
      end
      self.where_ast = self.where_ast.simplify
      raise unless criteria.where_ast.is_a?(MultiOperator)
    end

    self.with_index_name = criteria.with_index_name unless criteria.with_index_name.nil?
    self
  end

  def where_indexed?
    !!where_index_name
  end

  def where_index_name
    where_index_finder.index_name
  end

  def where_index_type
    where_index_finder.index_type
  end

  private

  class MultiOperator < Struct.new(:op, :clauses)
    def simplify
      clauses = self.clauses.map(&:simplify)
      if self.clauses.size == 1 && self.clauses.first.is_a?(self.class)
        return clauses.first
      end

      same_op_clauses, other_clauses = clauses.partition do |v|
        v.is_a?(self.class) && (v.clauses.size == 1 || v.op == self.op)
      end
      simplified_clauses = other_clauses + same_op_clauses.map(&:clauses).flatten(1)
      simplified_clauses =  BinaryOperator.simplify_clauses(op, simplified_clauses.uniq)
      self.class.new(op, simplified_clauses)
    end

    def to_rql(doc)
      case op
      when :and then clauses.map { |c| c.to_rql(doc) }.reduce { |a,b| a & b }
      when :or  then clauses.map { |c| c.to_rql(doc) }.reduce { |a,b| a | b }
      end
    end
  end

  class BinaryOperator < Struct.new(:key, :op, :value, :model, :casted_values)
    def self.get_candidate_clauses(clauses, *types)
      clauses.select { |c| c.is_a?(self) && types.include?(c.op) }
    end

    def self.simplify_clauses(op, ast_clauses)
      # This code assumes that simplfy() has already been called on all clauses.
      if op == :or
        eq_clauses = get_candidate_clauses(ast_clauses, :in, :eq)
        new_clauses = eq_clauses.group_by(&:key).map do |key, clauses|
          case clauses.size
          when 1 then clauses.first
          else
            values = clauses.map { |c| c.op == :in ? c.value : [c.value] }.flatten(1).uniq
            BinaryOperator.new(key, :in, values, clauses.first.model, true)
          end
        end

        if new_clauses.size != eq_clauses.size
          ast_clauses = ast_clauses - eq_clauses + new_clauses
        end
      end

      ast_clauses
    end

    def simplify
      key = cast_key(self.key)
      case op
      when :in then
        case value
        when Range then BinaryOperator.new(key, :between, (cast_value(value.min)..cast_value(value.max)), model, true)
        when Array then BinaryOperator.new(key, :in, value.map(&method(:cast_value)).uniq, model, true)
        else raise ArgumentError.new ":in takes an array/range, not #{value}"
        end
      when :between then BinaryOperator.new(key, :between, (cast_value(value.min)..cast_value(value.max)), model, true)
      else BinaryOperator.new(key, op, cast_value(value), model, true)
      end
    end

    def to_rql(doc)
      key = model.lookup_field_alias(self.key)
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
      @association ||= [model.association_metadata[key.to_sym]]
      @association.first
    end

    def cast_value(value)
      return value if casted_values

      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata
        target_klass = association.target_klass
        opts = { :attr_name => key, :value => value, :type => target_klass}
        raise NoBrainer::Error::InvalidType.new(opts) unless value.is_a?(target_klass)
        value.pk_value
      else
        model.cast_user_to_db_for(key, value)
      end
    end

    def cast_key(key)
      return key if casted_values

      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata then association.foreign_key
      else key
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
      else BinaryOperator.new(key.symbol, key.modifier, value, self.klass)
      end
    else raise "Invalid key: #{key}"
    end
  end

  def parse_clause_stub_eq(key, value)
    case value
    when Range  then BinaryOperator.new(key, :between, value, self.klass)
    when Regexp then BinaryOperator.new(key, :match, value.inspect[1..-2], self.klass)
    else BinaryOperator.new(key, :eq, value, self.klass)
    end
  end

  class IndexFinder < Struct.new(:criteria, :ast, :index_name, :index_type, :rql_proc)
    def initialize(*args)
      super
    end

    def could_find_index?
      !!self.index_name
    end

    def get_candidate_clauses(*types)
      BinaryOperator.get_candidate_clauses(ast.clauses, *types)
    end

    def get_usable_indexes(*types)
      @usable_indexes = {}
      @usable_indexes[types] ||= begin
        indexes = criteria.klass.indexes
        indexes = indexes.select { |k,v| types.include?(v[:kind]) } if types.present?
        if criteria.with_index_name && criteria.with_index_name != true
          indexes = indexes.select { |k,v| k == criteria.with_index_name.to_sym }
        end
        indexes
      end
    end

    def remove_from_ast(clauses)
      new_ast = MultiOperator.new(ast.op, ast.clauses - clauses)
      return new_ast if new_ast.clauses.present?
    end

    def find_index_canonical
      clauses = Hash[get_candidate_clauses(:eq, :in, :between).map { |c| [c.key, c] }]
      return unless clauses.present?

      if index_name = (get_usable_indexes.keys & clauses.keys).first
        clause = clauses[index_name]
        aliased_index = criteria.klass.indexes[index_name][:as]
        self.index_name = index_name
        self.ast = remove_from_ast([clause])
        self.index_type = clause.op == :between ? :between : :get_all
        self.rql_proc = case clause.op
          when :eq      then ->(rql){ rql.get_all(clause.value, :index => aliased_index) }
          when :in      then ->(rql){ rql.get_all(*clause.value, :index => aliased_index) }
          when :between then ->(rql){ rql.between(clause.value.min, clause.value.max, :index => aliased_index,
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
        aliased_index = criteria.klass.indexes[index_name][:as]
        self.index_name = index_name
        self.ast = remove_from_ast(indexed_clauses)
        self.index_type = :get_all
        self.rql_proc = ->(rql){ rql.get_all(indexed_clauses.map { |c| c.value }, :index => aliased_index) }
      end
    end

    def find_index_hidden_between
      clauses = get_candidate_clauses(:gt, :ge, :lt, :le).group_by(&:key)
      return unless clauses.present?

      if index_name = (get_usable_indexes.keys & clauses.keys).first
        op_clauses = Hash[clauses[index_name].map { |c| [c.op, c] }]
        left_bound = op_clauses[:gt] || op_clauses[:ge]
        right_bound = op_clauses[:lt] || op_clauses[:le]

        aliased_index = criteria.klass.indexes[index_name][:as]
        self.index_name = index_name
        self.ast = remove_from_ast([left_bound, right_bound].compact)

        options = {}
        options[:index] = aliased_index
        options[:left_bound]  = {:gt => :open, :ge => :closed}[left_bound.op] if left_bound
        options[:right_bound] = {:lt => :open, :le => :closed}[right_bound.op] if right_bound
        self.index_type = :between
        self.rql_proc = ->(rql){ rql.between(left_bound.try(:value), right_bound.try(:value), options) }
      end
    end

    def find_union_index
      indexes = []
      index_finder = self

      loop do
        index_finder = index_finder.dup
        break unless index_finder.find_index_canonical
        # TODO To use a compound index, we'd have to add all permutations in the query
        indexes << index_finder
        break unless index_finder.ast
      end

      if indexes.present? && !index_finder.ast
        self.ast = nil
        self.index_name = indexes.map(&:index_name)
        self.index_type = indexes.map(&:index_type)
        self.rql_proc = ->(rql){ indexes.map { |index| index.rql_proc.call(rql) }.reduce { |a,b| a.union(b) } }
      end
    end

    def find_index
      return if ast.nil? || criteria.without_index?
      case ast.op
      when :and then find_index_compound || find_index_canonical || find_index_hidden_between
      when :or  then find_union_index
      end
    end
  end

  def where_index_finder
    return with_default_scope_applied.__send__(:where_index_finder) if should_apply_default_scope?
    @where_index_finder ||= IndexFinder.new(self, where_ast).tap { |index_finder| index_finder.find_index }
  end

  def compile_rql_pass1
    rql = super
    rql = where_index_finder.rql_proc.call(rql) if where_index_finder.could_find_index?
    rql
  end

  def compile_rql_pass2
    rql = super
    ast = where_index_finder.could_find_index? ? where_index_finder.ast : self.where_ast
    rql = rql.filter { |doc| ast.to_rql(doc) } if ast.try(:clauses).present?
    rql
  end
end
