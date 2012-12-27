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
    @new_record
  end

  def destroyed?
    !!@destroyed
  end

  def persisted?
    !new_record? && !destroyed?
  end

  def reload
    assign_attributes(selector.run, :prestine => true)
  end

  def update_attributes(attrs, options={})
    assign_attributes(attrs, options)
    save
  end

  def update(&block)
    selector.update(&block)
  end

  def update_attribute(field, value)
    update_attributes(field => value)
  end

  def save(options={})
    run_callbacks :save do
      run_callbacks(new_record? ? :create : :update) do
        if new_record?
          result = NoBrainer.run { table.insert(attributes) }
          self.id ||= result['generated_keys'].first
          @new_record = false
        else
          selector.update { attributes }
        end
        true
      end
    end
  end

  def destroy
    run_callbacks :destroy do
      selector.delete
      @destroyed = true
      # TODO freeze attributes
      true
    end
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
