module NoBrainer::Document::Persistance
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :update, :save, :destroy, :terminator => 'false'
  end

  def _initialize(attrs={}, options={})
    super
    @new_record = !options[:from_db]
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

  def reload(options={})
    attrs = selector.raw.first!
    instance_variables.each { |ivar| remove_instance_variable(ivar) } unless options[:keep_ivars]
    initialize(attrs, :pristine => true, :from_db => true)
    self
  end

  def _create(options={})
    return false if options[:validate] && !valid?
    keys = self.class.insert_all(@_attributes)
    self.id ||= keys.first
    @new_record = false
    true
  end

  def _update(attrs)
    selector.update_all(attrs)
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
      selector.delete_all
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

    def insert_all(*attrs)
      result = NoBrainer.run(rql_table.insert(*attrs))
      result['generated_keys'].to_a
    end

    def sync
      NoBrainer.run(rql_table.sync)['synced'] == 1
    end
  end
end
