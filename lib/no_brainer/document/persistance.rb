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
    raise NoBrainer::Error::DocumentNotFound, "#{self.class} :#{self.class.pk_name}=>\"#{pk_value}\" not found" unless attrs

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
      next unless v = options.delete(type)

      v = Hash[v.flatten.map { |k| [k, true] }] if v.is_a?(Array)
      v = {v => true} unless v.is_a?(Hash)
      v = v.select { |k,_v| _v }
      v = v.with_indifferent_access
      next unless v.present?

      options[:missing_attributes] ||= {}
      options[:missing_attributes][type] = v
    end
    _reload(options)
  end

  def _create(options={})
    attrs = self.class.persistable_attributes(@_attributes, :instance => self)
    result = NoBrainer.run(self.class.rql_table.insert(attrs))
    self.pk_value ||= result['generated_keys'].to_a.first
    @new_record = false
    unlock_unique_fields # just an optimization for the uniquness validation
    true
  end

  def _update(attrs)
    rql = ->(doc){ self.class.persistable_attributes(attrs, :instance => self, :rql_doc => doc) }
    NoBrainer.run { selector.update(&rql) }
  end

  def _update_only_changed_attrs(options={})
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
    unlock_unique_fields # just an optimization for the uniquness validation
    true
  end

  def _save?(options={})
    new_record? ? _create(options) : _update_only_changed_attrs(options)
  end

  def save?(options={})
    _save?(options)
  end

  def save!(*args)
    save?(*args) or raise NoBrainer::Error::DocumentInvalid, self
  end

  def save(*args)
    save?(*args)
  end

  def update?(attrs, options={})
    assign_attributes(attrs, options)
    save?(options)
  end

  def update!(*args)
    update?(*args) or raise NoBrainer::Error::DocumentInvalid, self
  end
  alias_method :update_attributes!, :update!

  def update(*args)
    update?(*args)
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
      new(attrs, options).tap { |doc| doc.save?(options) }
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

    def persistable_key(k, options={})
      k
    end

    def persistable_value(k, v, options={})
      v
    end

    def persistable_attributes(attrs, options={})
      Hash[attrs.map { |k,v| [persistable_key(k, options), persistable_value(k, v, options)] }]
    end
  end
end
