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
    if options[:validate] && !valid?
      false
    else
      keys = self.class.insert_all(attributes)
      self.id ||= keys.first
      @new_record = false
      true
    end
  end

  def update(options={}, &block)
    if options[:validate] && !valid?
      false
    else
      selector.update_all(&block)
      true
    end
  end

  def replace(options={}, &block)
    if options[:validate] && !valid?
      false
    else
      selector.replace_all(&block)
      true
    end
  end

  def save(options={})
    options = options.reverse_merge(:validate => true)
    new_record? ? _create(options) : replace(options) { attributes }
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
