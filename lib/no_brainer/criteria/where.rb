module NoBrainer::Criteria::Where
  OPERATORS = %w(in nin eq ne not gt ge gte lt le lte defined).map(&:to_sym)

  require 'symbol_decoration'
  Symbol::Decoration.register(*OPERATORS)

  extend ActiveSupport::Concern

  included do
    criteria_option :where_ast, :merge_with => NoBrainer::Criteria::Where.method(:merge_where_ast)
  end

  def where(*args, &block)
    chain(:where_ast => parse_clause([*args, block].compact))
  end

  def self.merge_where_ast(a, b)
    (a ? MultiOperator.new(:and, [a, b]) : b).simplify
  end

  def where_present?
    finalized_criteria.options[:where_ast].try(:clauses).present?
  end

  def where_indexed?
    where_index_name.present?
  end

  def where_index_name
    index = where_index_finder.strategy.try(:index)
    index.is_a?(Array) ? index.map(&:name) : index.try(:name)
  end

  def where_index_type
    where_index_finder.strategy.try(:rql_op)
  end

  private

  class MultiOperator < Struct.new(:op, :clauses)
    def simplify
      clauses = self.clauses.map(&:simplify)
      if clauses.size == 1 && clauses.first.is_a?(self.class)
        return clauses.first
      end

      same_op_clauses, other_clauses = clauses.partition do |v|
        v.is_a?(self.class) && (v.clauses.size == 1 || v.op == self.op)
      end
      simplified_clauses = other_clauses + same_op_clauses.map(&:clauses).flatten(1)
      simplified_clauses = BinaryOperator.simplify_clauses(op, simplified_clauses.uniq)
      self.class.new(op, simplified_clauses)
    end

    def to_rql(doc)
      case op
      when :and then clauses.map { |c| c.to_rql(doc) }.reduce(:&)
      when :or  then clauses.map { |c| c.to_rql(doc) }.reduce(:|)
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
        target_model = association.target_model
        opts = { :attr_name => key, :value => value, :type => target_model}
        raise NoBrainer::Error::InvalidType.new(opts) unless value.is_a?(target_model)
        value.pk_value
      else
        model.cast_user_to_db_for(key, value)
      end
    end

    def cast_key(key)
      return key if casted_values

      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata then association.foreign_key
      else
        unless model.has_field?(key) || model.has_index?(key) || model < NoBrainer::Document::DynamicAttributes
          raise NoBrainer::Error::UnknownAttribute, "`#{key}' is not a declared attribute of #{model}"
        end
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
    when Symbol::Decoration
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
    when Symbol::Decoration then
      case key.decorator
      when :nin then parse_clause(:not => { key.symbol.in => value })
      when :not, :ne then parse_clause(:not => { key.symbol.eq => value })
      when :gte then parse_clause(key.symbol.ge => value)
      when :lte then parse_clause(key.symbol.le => value)
      when :eq  then parse_clause_stub_eq(key.symbol, value)
      else BinaryOperator.new(key.symbol, key.decorator, value, self.model)
      end
    else raise "Invalid key: #{key}"
    end
  end

  def parse_clause_stub_eq(key, value)
    case value
    when Range  then BinaryOperator.new(key, :between, value, self.model)
    when Regexp then BinaryOperator.new(key, :match, value.inspect[1..-2], self.model)
    else BinaryOperator.new(key, :eq, value, self.model)
    end
  end

  class IndexFinder < Struct.new(:criteria, :ast, :strategy)
    class Strategy < Struct.new(:rql_op, :index, :ast, :rql_proc); end
    class IndexStrategy < Struct.new(:criteria_ast, :optimized_clauses, :index, :rql_op, :rql_args, :rql_options)
      def ast
        MultiOperator.new(criteria_ast.op, criteria_ast.clauses - optimized_clauses)
      end

      def rql_proc
        ->(rql){ rql.__send__(rql_op, *rql_args, (rql_options || {}).merge(:index => index.aliased_name)) }
      end
    end

    def get_candidate_clauses(*types)
      BinaryOperator.get_candidate_clauses(ast.clauses, *types)
    end

    def get_usable_indexes(options={})
      indexes = criteria.model.indexes.values
      options.each { |k,v| indexes = indexes.select { |i| v == i.__send__(k) } }
      if criteria.options[:use_index] && criteria.options[:use_index] != true
        indexes = indexes.select { |i| i.name == criteria.options[:use_index].to_sym }
      end
      indexes
    end

    def find_strategy_canonical
      clauses = Hash[get_candidate_clauses(:eq, :in, :between).map { |c| [c.key, c] }]
      return nil unless clauses.present?

      get_usable_indexes.each do |index|
        clause = clauses[index.name]
        next unless clause

        args = case clause.op
          when :eq      then [:get_all, [clause.value]]
          when :in      then [:get_all, clause.value]
          when :between then [:between, [clause.value.min, clause.value.max],
                              :left_bound => :closed, :right_bound => :closed]
        end
        return IndexStrategy.new(ast, [clause], index, *args)
      end
      return nil
    end

    def find_strategy_compound
      clauses = Hash[get_candidate_clauses(:eq).map { |c| [c.key, c] }]
      return nil unless clauses.present?

      get_usable_indexes(:kind => :compound).each do |index|
        indexed_clauses = index.what.map { |field| clauses[field] }
        next if indexed_clauses.any?(&:nil?)

        return IndexStrategy.new(ast, indexed_clauses, index, :get_all, [indexed_clauses.map(&:value)])
      end
      return nil
    end

    def find_strategy_hidden_between
      clauses = get_candidate_clauses(:gt, :ge, :lt, :le).group_by(&:key)
      return nil unless clauses.present?

      get_usable_indexes.each do |index|
        next unless clauses[index.name]
        op_clauses = Hash[clauses[index.name].map { |c| [c.op, c] }]
        left_bound  = op_clauses[:gt] || op_clauses[:ge]
        right_bound = op_clauses[:lt] || op_clauses[:le]

        options = {}
        options[:left_bound]  = {:gt => :open, :ge => :closed}[left_bound.op]  if left_bound
        options[:right_bound] = {:lt => :open, :le => :closed}[right_bound.op] if right_bound

        return IndexStrategy.new(ast, [left_bound, right_bound].compact, index, :between,
                                 [left_bound.try(:value), right_bound.try(:value)], options)
      end
      return nil
    end

    def find_strategy_union
      strategies = ast.clauses.map do |inner_ast|
        inner_ast = MultiOperator.new(:and, [inner_ast]) unless inner_ast.is_a?(MultiOperator)
        raise 'fatal' unless inner_ast.op == :and
        self.class.new(criteria, inner_ast).find_strategy
      end

      return nil if strategies.any?(&:nil?)

      rql_proc = lambda do |base_rql|
        strategies.map do |strategy|
          rql = strategy.rql_proc.call(base_rql)
          rql = rql.filter { |doc| strategy.ast.to_rql(doc) } if strategy.ast.try(:clauses).present?
          rql
        end.reduce(:union).distinct
      end

      Strategy.new(:union, strategies.map(&:index), nil, rql_proc)
    end

    def find_strategy
      return nil unless ast.try(:clauses).present? && !criteria.without_index?
      case ast.op
      when :and then find_strategy_compound || find_strategy_canonical || find_strategy_hidden_between
      when :or  then find_strategy_union
      end
    end

    def find_strategy!
      self.strategy = find_strategy
    end
  end

  def where_index_finder
    return finalized_criteria.__send__(:where_index_finder) unless finalized?
    @where_index_finder ||= IndexFinder.new(self, @options[:where_ast]).tap(&:find_strategy!)
  end

  def compile_rql_pass1
    rql = super
    rql = where_index_finder.strategy.rql_proc.call(rql) if where_indexed?
    rql
  end

  def compile_rql_pass2
    rql = super
    ast = where_indexed? ? where_index_finder.strategy.ast : @options[:where_ast]
    rql = rql.filter { |doc| ast.to_rql(doc) } if ast.try(:clauses).present?
    rql
  end
end
