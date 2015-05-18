module NoBrainer::Document::Callbacks
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks

    define_model_callbacks :initialize, :create, :update, :save, :destroy, :terminator => proc { false }
    define_model_callbacks :find, :only => [:after], :terminator => proc { false }
  end

  def initialize(*args, &block)
    run_callbacks(:initialize) { _initialize(*args, &block); true }
  end

  def _create(*args, &block)
    run_callbacks(:create) { super }
  end

  def _update_only_changed_attrs(*args, &block)
    run_callbacks(:update) { super }
  end

  def save?(*args, &block)
    run_callbacks(:save) { super }
  end

  def destroy(*args, &block)
    run_callbacks(:destroy) { super }
  end
end
