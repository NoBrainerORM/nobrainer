module NoBrainer::Base::Persistance
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :update, :save, :destroy
  end

  # TODO after_initialize callback
  def initialize(attrs={})
    @new_record = true
  end

  def raw_initialize(attrs={})
    @new_record = false
  end

  def new_record?
    @new_record
  end

  def persisted?
    !new_record?
  end

  def reload
    self.class._find(id) { |attrs| @attributes = attrs }
  end

  def update_attribute(field, value)
    __send__("#{field}=", value)
    save
  end

  def update_attributes(hash)
    hash.each { |field, value| __send__("#{field}=", value) }
    save
  end

  def save
    run_callbacks(new_record? ? :create : :update) do
      run_callbacks :save do
        if new_record?
          result = NoBrainer.run { table.insert(attributes) }
          # TODO self.id= or @attributes['id']= ?
          @attributes['id'] ||= result['generated_keys'].first
          @new_record = false
        else
          NoBrainer.run { selector.update { attributes } }
        end
        true
      end
    end
  end

  def destroy
    run_callbacks :destroy do
      NoBrainer.run { selector.delete }
      true
    end
  end

  module ClassMethods
    def create(*args)
      new(*args).tap { |model| model.save }
    end
  end
end
