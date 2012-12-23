module NoBrainer::Base::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :validation
  end

  def save
    run_callbacks :validation do
      valid? ? super : false
    end
  end

  [:save, :update_attributes, :update_attribute].each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}!(*args)
        raise NoBrainer::Error::Validations, errors unless #{method}(*args)
      end
    RUBY
  end

  module ClassMethods
    # TODO DRY this up
    def create!(*args)
      create(*args).tap do |model|
        if model.errors.present?
          raise NoBrainer::Error::Validations, model.errors
        end
      end
    end
  end
end
