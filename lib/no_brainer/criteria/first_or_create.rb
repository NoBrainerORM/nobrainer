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
    attrs = model.association_user_to_model_cast(attrs)
    unique_keys = get_model_unique_fields.detect { |keys| keys & attrs.keys == keys }
    return where(attrs.slice(*unique_keys)).__send__(:_first_or_create, attrs, save_options) if unique_keys

    # We can't do an upsert :( Let see if we can fail on a validator first...
    instance = model.new(attrs)
    unless instance.valid?
      case save_options[:save_method]
      when :save! then raise NoBrainer::Error::DocumentInvalid, instance
      when :save? then return instance
      end
    end

    raise "Could not find a uniqueness validator for the following keys: `#{attrs.keys.inspect}'."
  end

  def _first_or_create(create_params, save_options, &block)
    raise "Cannot use .raw() with .first_or_create()" if raw?

    if block && block.arity == 1
      raise "When passing a block to first_or_create(), you must pass a block with no arguments.\n" +
            "The passed block must return a hash of additional attributes for create()"
    end

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

    unless model.is_root_class? || (model.superclass.fields.keys & keys).empty?
      # We can't allow the parent to share the keys we are matching on.
      # Consider this case:
      # - Base has the field :name, :uniq => true declared
      # - A < Base
      # - B < Base
      # - A.create(:name => 'x'),
      # - B.where(:name => 'x').first_or_create
      # We are forced to return nil, or raise.
      parent = model
      parent = parent.superclass while parent.superclass < NoBrainer::Document &&
                                      !(parent.superclass.fields.keys & keys).empty?
      raise "A polymorphic problem has been detected: The fields `#{keys.inspect}' are defined on `#{parent}'.\n" +
            "This is problematic as first_or_create() could return nil in some cases.\n" +
            "Either 1) Only define `#{keys.inspect}' on `#{model}', \n" +
            "or     2) Query the superclass, and pass :_type in first_or_create() as such:\n" +
            "          `#{parent}.where(...).first_or_create(:_type => \"#{model}\")'."
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
           where_clauses.op == :and
      raise "Please use a query of the form `.where(...).first_or_create(...)'"
    end

    Hash[where_clauses.clauses.map do |c|
      unless c.is_a?(NoBrainer::Criteria::Where::BinaryOperator) &&
             c.op == :eq && c.key_modifier == :scalar
        # Ignore params on the subclass type, we are handling this case directly
        # in _first_or_create()
        next if c.key_path == [:_type]
        raise "Please only use equal constraints in your where() query when using first_or_create()"
      end

      raise "You may not use nested hash queries with first_or.create()" if c.key_path.size > 1
      [c.key_path.first.to_sym, c.value]
    end.compact].tap { |h| raise "Missing where() clauses for first_or_create()" if h.empty? }
  end

  def get_model_unique_fields
    [[model.pk_name]] +
      model.unique_validators
     .flat_map { |validator| validator.attributes.map { |attr| [attr, validator] } }
     .map { |f, validator| [f, *validator.scope].map(&:to_sym).sort }
  end
end
