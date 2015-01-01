module NoBrainer::Criteria::Where
  NON_CHAINABLE_OPERATORS = %w(in nin eq ne not gt ge gte lt le lte defined near intersects).map(&:to_sym)
  CHAINABLE_OPERATORS = %w(any all).map(&:to_sym)
  OPERATORS = CHAINABLE_OPERATORS + NON_CHAINABLE_OPERATORS

  require 'symbol_decoration'
  Symbol::Decoration.register(*NON_CHAINABLE_OPERATORS)
  Symbol::Decoration.register(*CHAINABLE_OPERATORS, :chainable => true)

  extend ActiveSupport::Concern

  included do
    criteria_option :where_ast, :merge_with => NoBrainer::Criteria::Where.method(:merge_where_ast)
    criteria_option :without_distinct, :merge_with => :set_scalar
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

  def without_distinct(value = true)
    # helper for delete_all which can't operate on distinct
    chain(:without_distinct => value)
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

  class BinaryOperator < Struct.new(:key, :key_modifier, :op, :value, :model, :casted_values)
    def self.get_candidate_clauses(clauses, *types)
      clauses.select { |c| c.is_a?(self) && types.include?(c.op) }
    end

    def self.simplify_clauses(op, ast_clauses)
      # This code assumes that simplfy() has already been called on all clauses.
      if op == :or
        eq_clauses = get_candidate_clauses(ast_clauses, :in, :eq)
        new_clauses = eq_clauses.group_by { |c| [c.key, c.key_modifier] }.map do |(key, key_modifier), clauses|
          if key_modifier.in?([:scalar, :any]) && clauses.size > 1
            values = clauses.map { |c| c.op == :in ? c.value : [c.value] }.flatten(1).uniq
            [BinaryOperator.new(key, key_modifier, :in, values, clauses.first.model, true)]
          else
            clauses
          end
        end.flatten(1)

        if new_clauses.size != eq_clauses.size
          ast_clauses = ast_clauses - eq_clauses + new_clauses
        end
      end

      ast_clauses
    end

    def simplify
      new_key = cast_key(key)
      new_op, new_value = case op
        when :in then
          case value
          when Range then [:between, (cast_value(value.min)..cast_value(value.max))]
          when Array then [:in, value.map(&method(:cast_value)).uniq]
          else raise ArgumentError.new "`in' takes an array/range, not #{value}"
          end
        when :between then [op, (cast_value(value.min)..cast_value(value.max))]
        when :defined
          raise "Incorrect use of `#{op}' and `#{key_modifier}'" if key_modifier != :scalar
          [op, cast_value(value)]
        else [op, cast_value(value)]
      end
      BinaryOperator.new(new_key, key_modifier, new_op, new_value, model, true)
    end

    def to_rql(doc)
      key = model.lookup_field_alias(self.key)

      case key_modifier
      when :scalar then
        case op
        when :defined then value ? doc.has_fields(key) : doc.has_fields(key).not
        else to_rql_scalar(doc[key])
        end
      when :any then doc[key].map { |lvalue| to_rql_scalar(lvalue) }.contains(true)
      when :all then doc[key].map { |lvalue| to_rql_scalar(lvalue) }.contains(false).not
      end
    end

    def to_rql_scalar(lvalue)
      case op
      when :between    then (lvalue >= value.min) & (lvalue <= value.max)
      when :in         then RethinkDB::RQL.new.expr(value).contains(lvalue)
      when :intersects then lvalue.intersects(value.to_rql)
      when :near
        options = value.dup
        point = options.delete(:point)
        max_dist = options.delete(:max_dist)
        # XXX max_results is not used, seems to be a workaround of rethinkdb index implemetnation.
        _ = options.delete(:max_results)
        RethinkDB::RQL.new.distance(lvalue, point.to_rql, options) <= max_dist
      else lvalue.__send__(op, value)
      end
    end

    def compatible_with_index?(index)
      [key_modifier, index.multi].in?([[:any, true], [:scalar, false]])
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
        opts = { :attr_name => key, :value => value, :type => target_model }
        raise NoBrainer::Error::InvalidType.new(opts) unless value.is_a?(target_model)
        value.pk_value
      else
        case op
        when :defined then NoBrainer::Boolean.nobrainer_cast_user_to_model(value)
        when :intersects
          raise "Use a geo object with `intersects`" unless value.is_a?(NoBrainer::Geo::Base)
          value
        when :near
          raise "Incorrect use of `near': rvalue must be a hash" unless value.is_a?(Hash)
          options = NoBrainer::Geo::Base.normalize_geo_options(value)

          unless options[:point] && options[:max_dist]
            raise "`near' takes something like {:point => P, :max_distance => d}"
          end

          unless options[:point].is_a?(NoBrainer::Geo::Point)
            options[:point] = NoBrainer::Geo::Point.nobrainer_cast_user_to_model(options[:point])
          end

          options
        else
          case key_modifier
          when :scalar    then model.cast_user_to_db_for(key, value)
          when :any, :all then model.cast_user_to_db_for(key, [value]).first
          end
        end
      end
    end

    def cast_key(key)
      return key if casted_values

      case association
      when NoBrainer::Document::Association::BelongsTo::Metadata then association.foreign_key
      else ensure_valid_key!(key); key
      end
    end

    def ensure_valid_key!(key)
      return if model.has_field?(key) || model.has_index?(key) || model < NoBrainer::Document::DynamicAttributes
      raise NoBrainer::Error::UnknownAttribute, "`#{key}' is not a declared attribute of #{model}"
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
    when :and then parse_multi_value(:and, value)
    when :or  then parse_multi_value(:or,  value)
    when :not then UnaryOperator.new(:not, parse_clause(value))
    when String, Symbol then parse_clause_stub_eq(key, value)
    when Symbol::Decoration then
      case key.decorator
      when :any, :all then parse_clause_stub_eq(key, value)
      when :not, :ne  then parse_clause(:not => { key.symbol.eq => value })
      when :nin then parse_clause(:not => { key.symbol.in => value })
      when :gte then parse_clause(key.symbol.ge => value)
      when :lte then parse_clause(key.symbol.le => value)
      when :eq  then parse_clause_stub_eq(key.symbol, value)
      else instantiate_binary_op(key.symbol, key.decorator, value)
      end
    else raise "Invalid key: #{key}"
    end
  end

  def parse_multi_value(op, value)
    raise "The `#{op}' operator takes an array as argument" unless value.is_a?(Array)
    if value.size == 1 && value.first.is_a?(Hash)
      raise "The `#{op}' operator was provided an array with a single hash element.\n" +
            "In Ruby, [:a => :b, :c => :d] means [{:a => :b, :c => :d}] which is not the same as [{:a => :b}, {:c => :d}].\n" +
            "To prevent mistakes, the former construct is prohibited as you probably mean the latter."
    end
    MultiOperator.new(op, value.map { |v| parse_clause(v) })
  end

  def parse_clause_stub_eq(key, value)
    case value
    when Range  then instantiate_binary_op(key, :between, value)
    when Regexp then instantiate_binary_op(key, :match, value.inspect[1..-2])
    else instantiate_binary_op(key, :eq, value)
    end
  end

  def instantiate_binary_op(key, op, value)
    case key
    when Symbol::Decoration then BinaryOperator.new(key.symbol, key.decorator, op, value, self.model)
    else BinaryOperator.new(key, :scalar, op, value, self.model)
    end
  end

  class IndexFinder < Struct.new(:criteria, :ast, :strategy)
    class Strategy < Struct.new(:index_finder, :rql_op, :index, :ast, :rql_proc); end
    class IndexStrategy < Struct.new(:index_finder, :criteria_ast, :optimized_clauses, :index, :rql_op, :rql_args, :rql_options)
      def ast
        MultiOperator.new(criteria_ast.op, criteria_ast.clauses - optimized_clauses)
      end

      def rql_proc
        lambda do |rql|
          opt = (rql_options || {}).merge(:index => index.aliased_name)
          r = rql.__send__(rql_op, *rql_args, opt)
          r = r.map { |i| i['doc'] } if rql_op == :get_nearest
          # TODO distinct: waiting for issue #3345
          # TODO coerce_to: waiting for issue #3346
          r = r.coerce_to('array').distinct if index.multi && !index_finder.criteria.options[:without_distinct]
          r
        end
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
      clauses = get_candidate_clauses(:eq, :in, :between, :near, :intersects)
      return nil unless clauses.present?

      usable_indexes = Hash[get_usable_indexes.map { |i| [i.name, i] }]
      clauses.map do |clause|
        index = usable_indexes[clause.key]
        next unless index && clause.compatible_with_index?(index)
        next unless index.geo == [:near, :intersects].include?(clause.op)

        args = case clause.op
          when :intersects then [:get_intersecting, clause.value.to_rql]
          when :near
            options = clause.value.dup
            point = options.delete(:point)
            [:get_nearest, point.to_rql, options]
          when :eq      then [:get_all, [clause.value]]
          when :in      then [:get_all, clause.value]
          when :between then [:between, [clause.value.min, clause.value.max],
                              :left_bound => :closed, :right_bound => :closed]
        end
        IndexStrategy.new(self, ast, [clause], index, *args)
      end.compact.sort_by { |strat| usable_indexes.values.index(strat.index) }.first
    end

    def find_strategy_compound
      clauses = Hash[get_candidate_clauses(:eq).map { |c| [c.key, c] }]
      return nil unless clauses.present?

      get_usable_indexes(:kind => :compound, :geo => false, :multi => false).each do |index|
        indexed_clauses = index.what.map { |field| clauses[field] }
        next unless indexed_clauses.all? { |c| c.try(:compatible_with_index?, index) }

        return IndexStrategy.new(self, ast, indexed_clauses, index, :get_all, [indexed_clauses.map(&:value)])
      end
      return nil
    end

    def find_strategy_hidden_between
      clauses = get_candidate_clauses(:gt, :ge, :lt, :le).group_by(&:key)
      return nil unless clauses.present?

      get_usable_indexes(:geo => false).each do |index|
        matched_clauses = clauses[index.name].try(:select) { |c| c.compatible_with_index?(index) }
        next unless matched_clauses.present?

        op_clauses = Hash[matched_clauses.map { |c| [c.op, c] }]
        left_bound  = op_clauses[:gt] || op_clauses[:ge]
        right_bound = op_clauses[:lt] || op_clauses[:le]

        # XXX we must keep only one bound when using `any', otherwise we get different semantics.
        right_bound = nil if index.multi && left_bound && right_bound

        options = {}
        options[:left_bound]  = {:gt => :open, :ge => :closed}[left_bound.op]  if left_bound
        options[:right_bound] = {:lt => :open, :le => :closed}[right_bound.op] if right_bound

        return IndexStrategy.new(self, ast, [left_bound, right_bound].compact, index, :between,
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

      Strategy.new(self, :union, strategies.map(&:index), nil, rql_proc)
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
