module NoBrainer::Document::Persistance
  extend ActiveSupport::Concern

  def _initialize(attrs={}, options={})
    @new_record = !options[:from_db]
    super
  end

  def new_record?
    !!@new_record
  end

  def destroyed?
    !!@destroyed
  end

  def persisted?
    !new_record? && !destroyed?
  end

  def _reload_selector(options={})
    rql = selector
    if opt = options[:missing_attributes]
      rql = rql.pluck(self.class.with_fields_aliased(opt[:pluck])) if opt[:pluck]
      rql = rql.without(self.class.with_fields_aliased(opt[:without])) if opt[:without]
    end
    rql
  end

  def _reload(options={})
    attrs = NoBrainer.run { _reload_selector(options) }
    raise NoBrainer::Error::DocumentNotFound, "#{self.class} #{self.class.pk_name}: #{pk_value} not found" unless attrs

    options = options.merge(:pristine => true, :from_db => true)

    if options[:keep_ivars]
      assign_attributes(attrs, options)
    else
      instance_variables.each { |ivar| remove_instance_variable(ivar) }
      initialize(attrs, options)
    end

    self
  end

  def reload(options={})
    [:without, :pluck].each do |type|
      if v = options.delete(type)
        v = Hash[v.flatten.map { |k| [k, true] }] if v.is_a?(Array)
        v = {v => true} if !v.is_a?(Hash)
        v = v.select { |k,_v| _v }
        v = v.with_indifferent_access
        next unless v.present?

        options[:missing_attributes] ||= {}
        options[:missing_attributes][type] = v
      end
    end
    _reload(options)
  end

  def _create(options={})
    return false if options[:validate] && !valid?
    keys = self.class.insert_all(@_attributes)
    self.pk_value ||= keys.first
    @new_record = false
    true
  end

  def _update(attrs)
    attrs = self.class.persistable_attributes(attrs)
    NoBrainer.run { selector.update(attrs) }
  end

  def _update_only_changed_attrs(options={})
    return false if options[:validate] && !valid?

    # We won't be using the `changes` values, because they went through
    # read_attribute(), and we want the raw values.
    attrs = Hash[self.changed.map do |k|
      attr = @_attributes[k]
      # If we have a hash to save, we need to specify r.literal(),
      # otherwise, the hash would just get merged with the existing one.
      attr = RethinkDB::RQL.new.literal(attr) if attr.is_a?(Hash)
      [k, attr]
    end]
    _update(attrs) if attrs.present?
    true
  end

  def save(options={})
    options = options.reverse_merge(:validate => true)
    new_record? ? _create(options) : _update_only_changed_attrs(options)
  end

  def save!(*args)
    save(*args) or raise NoBrainer::Error::DocumentInvalid, self
  end

  def update_attributes(attrs, options={})
    assign_attributes(attrs, options)
    save(options)
  end

  def update_attributes!(*args)
    update_attributes(*args) or raise NoBrainer::Error::DocumentInvalid, self
  end

  def delete
    unless @destroyed
      NoBrainer.run { selector.delete }
      @destroyed = true
    end
    @_attributes.freeze
    true
  end

  def destroy
    delete
  end

  module ClassMethods
    def create(attrs={}, options={})
      new(attrs, options).tap { |doc| doc.save(options) }
    end

    def create!(attrs={}, options={})
      new(attrs, options).tap { |doc| doc.save!(options) }
    end

    def insert_all(*args)
      docs = args.shift
      docs = [docs] unless docs.is_a?(Array)
      docs = docs.map { |doc| persistable_attributes(doc) }
      result = NoBrainer.run(rql_table.insert(docs, *args))
      result['generated_keys'].to_a
    end

    def sync
      NoBrainer.run(rql_table.sync)['synced'] == 1
    end

    def persistable_key(k)
      k
    end

    def persistable_value(k, v)
      v
    end

    def persistable_attributes(attrs)
      Hash[attrs.map { |k,v| [persistable_key(k), persistable_value(k, v)] }]
    end
  end
end
