module NoBrainer::Document::Callbacks
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :initialize, :create, :update, :save, :destroy, :terminator => 'false'
    define_model_callbacks :find, :only => [:after], :terminator => 'false'
  end

  def initialize(*args)
    run_callbacks(:initialize) { _initialize(*args); true }
  end

  def _create(*args)
    run_callbacks(:create) { super }
  end

  def update(*args, &block)
    run_callbacks(:update) { super }
  end

  def replace(*args, &block)
    run_callbacks(:update) { super }
  end

  def _update_changed(*args)
    run_callbacks(:update) { super }
  end

  def save(*args)
    run_callbacks(:save) { super }
  end

  def destroy(*args)
    run_callbacks(:destroy) { super }
  end
end
