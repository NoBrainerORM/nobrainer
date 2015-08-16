module NoBrainer::Criteria::FirstOrCreate
  extend ActiveSupport::Concern

  def first_or_create(create_params={}, save_options={}, &block)
    _first_or_create(create_params, save_options.merge(:save_method => :save?), &block)
  end

  def first_or_create!(create_params={}, save_options={}, &block)
    _first_or_create(create_params, save_options.merge(:save_method => :save!), &block)
  end

  def upsert(attrs, save_options={})
    _upsert(attrs, save_options.merge(:save_method => :save?, :update => true))
  end

  def upsert!(attrs, save_options={})
    _upsert(attrs, save_options.merge(:save_method => :save!, :update => true))
  end

  private

  def _upsert(attrs, save_options)
    attrs = attrs.symbolize_keys
    unique_keys = get_model_unique_fields.detect { |keys| keys & attrs.keys == keys }
    raise "Could not find a uniqueness validator within `#{attrs.keys.inspect}'.\n" +
           "Please add a corresponding uniqueness validator" unless unique_keys
    where(attrs.slice(*unique_keys)).__send__(:_first_or_create, attrs, save_options)
  end

  def _first_or_create(create_params, save_options, &block)
    raise "Cannot use .raw() with .first_or_create()" if raw?
    raise "Use first_or_create() on the root class `#{model.root_class}'" unless model.is_root_class?

    save_method = save_options.delete(:save_method)
    should_update = save_options.delete(:update)

    where_params = extract_where_params()

    # Note that we are not matching a subset of the keys on the uniqueness
    # validators; we need an exact match on the keys.
    keys = where_params.keys
    unless get_model_unique_fields.include?(keys.sort)
      # We could do without a uniqueness validator, but it's much preferable to
      # have it, so that we don't conflict with others create(), not just others
      # first_or_create().
      raise "Please add the following uniqueness validator for first_or_create():\n" +
        "class #{model}\n" +
          case keys.size
          when 1 then "  field :#{keys.first}, :uniq => true"
          when 2 then "  field :#{keys.first}, :uniq => {:scope => :#{keys.last}}"
          else        "  field :#{keys.first}, :uniq => {:scope => #{keys[1..-1].inspect}}"
          end +
        "\nend"
    end

    # We don't want to access create_params yet, because invoking the block
    # might be costly (the user might be doing some API call or w/e), and
    # so we want to invoke the block only if necessary.
    new_instance = model.new(where_params)
    lock_key_name = model._uniqueness_key_name_from_params(where_params)
    new_instance._lock_for_uniqueness_once(lock_key_name)

    old_instance = self.first
    if old_instance
      if should_update
        old_instance.assign_attributes(create_params)
        old_instance.__send__(save_method, save_options)
      end
      return old_instance
    end

    create_params = block.call if block
    create_params = create_params.symbolize_keys

    keys_in_conflict = create_params.keys & where_params.keys
    keys_in_conflict = keys_in_conflict.reject { |k| create_params[k] == where_params[k] }
    unless keys_in_conflict.empty?
      raise "where() and first_or_create() were given conflicting values " +
            "on the following keys: #{keys_in_conflict.inspect}"
    end

    if create_params[:_type]
      # We have to recreate the instance because we are given a _type in
      # create_params specifying a subclass. We'll have to transfert the lock
      # ownership to that new instance.
      new_instance = model.model_from_attrs(create_params).new(where_params).tap do |i|
        i.locked_keys_for_uniqueness = new_instance.locked_keys_for_uniqueness
      end
    end

    new_instance.assign_attributes(create_params)
    new_instance.__send__(save_method, save_options)
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

  def get_model_unique_fields
    [[model.pk_name]] +
      model.unique_validators
     .flat_map { |validator| validator.attributes.map { |attr| [attr, validator] } }
     .map { |f, validator| [f, *validator.scope].map(&:to_sym).sort }
  end
end
