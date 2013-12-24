module NoBrainer::Document::Persistance
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :update, :save, :destroy
  end

  # TODO after_initialize, after_find callback
  def initialize(attrs={}, options={})
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

  def _create
    run_callbacks :create do
      result = NoBrainer.run { self.class.rql_table.insert(attributes) }
      self.id ||= result['generated_keys'].first
      @new_record = false
      true
    end
  end

  def reload(options={})
    unless options[:keep_ivars]
      id = self.id
      instance_variables.each { |ivar| remove_instance_variable(ivar) }
      @attributes = {}
      self.id = id
    end
    assign_attributes(selector.raw.first!, :pristine => true, :from_db => true)
    self
  end

  def update(&block)
    run_callbacks :update do
      selector.update_all(&block)
      true
    end
  end

  def replace(&block)
    run_callbacks :update do
      selector.replace_all(&block)
      true
    end
  end

  def save(options={})
    run_callbacks :save do
      new_record? ? _create : replace { attributes }
    end
  end

  def update_attributes(attrs, options={})
    assign_attributes(attrs, options)
    save(options)
  end

  def delete
    unless @destroyed
      selector.delete_all
      @destroyed = true
    end
    # TODO freeze attributes
    true
  end

  def destroy
    run_callbacks(:destroy) { delete }
  end

  module ClassMethods
    def create(*args)
      new(*args).tap { |doc| doc.save }
    end

    def create!(*args)
      new(*args).tap { |doc| doc.save! }
    end
  end
end
