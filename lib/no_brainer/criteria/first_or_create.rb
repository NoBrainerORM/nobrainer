module NoBrainer::Criteria::FirstOrCreate
  extend ActiveSupport::Concern

  def first_or_create(create_params={}, &block)
    _first_or_create(create_params, :save_method => :save?, &block)
  end

  def first_or_create!(create_params={}, &block)
    _first_or_create(create_params, :save_method => :save!, &block)
  end

  private

  def _first_or_create(create_params={}, options={}, &block)
    raise "Cannot use .raw() with .first_or_create()" if raw?

    where_params = extract_where_params()
    keys = where_params.keys

    # When matching on the primary key, we'll just pretend that we have a
    # uniqueness validator on it. We will be racy against other create(),
    # but not on first_or_create().
    # And if we get caught in a race with another create(), we'll just have a
    # duplicate primary key exception.
    matched_validator = true if keys == [model.pk_name]
    matched_validator ||= !!get_uniqueness_validators_map[keys.sort]
    unless matched_validator
      # We could do without a uniqueness validator, but it's much preferable to
      # have it, so that we don't conflict with others create(), not just others
      # first_or_create().
      raise "Please add the following uniqueness validator for first_or_create():\n" +
        "class #{model}\n" +
          case keys.size
          when 1 then "  field :#{keys.first}, :uniq => true"
          when 2 then "  field :#{keys.first}, :uniq => {:scope => :#{keys.last}}"
          else        "  field :#{keys.first}, :uniq => {:scope => #{keys[1..-1].inspect}"
          end +
        "\nend"
    end

    lock_key_name = model._uniqueness_key_name_from_params(where_params)
    new_instance = model.new(where_params)
    new_instance._lock_for_uniqueness_once(lock_key_name)

    old_instance = self.first
    return old_instance if old_instance

    create_params = block.call if block
    create_params = create_params.symbolize_keys

    keys_in_conflict = create_params.keys & where_params.keys
    keys_in_conflict = keys_in_conflict.select { |k| create_params[k] == where_params[k] }
    unless keys_in_conflict.empty?
      raise "where() and first_or_create() were given conflicting values " +
            "on the following keys: #{keys_in_conflict.inspect}"
    end

    new_instance.assign_attributes(create_params)
    new_instance.__send__(options[:save_method])
    return new_instance
  ensure
    new_instance.try(:unlock_unique_fields)
  end

  def extract_where_params()
    where_clauses = finalized_criteria.options[:where_ast]

    unless where_clauses.is_a?(NoBrainer::Criteria::Where::MultiOperator) &&
           where_clauses.op == :and && where_clauses.clauses.size > 0 &&
           where_clauses.clauses.all? do |c|
             c.is_a?(NoBrainer::Criteria::Where::BinaryOperator) &&
             c.op == :eq && c.key_modifier == :scalar
           end
      raise "Please use a query of the form `.where(...).first_or_create(...)'"
    end

    Hash[where_clauses.clauses.map do |c|
      raise "You may not use nested hash queries with first_or.create()" if c.key_path.size > 1
      [c.key_path.first.to_sym, c.value]
    end]
  end

  def get_uniqueness_validators_map
    Hash[model.unique_validators
     .flat_map { |validator| validator.attributes.map { |attr| [attr, validator] } }
     .map { |f, validator| [[f, *validator.scope].map(&:to_sym).sort, validator] }]
  end
end
