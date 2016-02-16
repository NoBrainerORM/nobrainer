module NoBrainer::Document::Callbacks
  extend ActiveSupport::Concern

  def self.define_callbacks_options(options={})
    if ActiveSupport::Callbacks.respond_to?(:halt_and_display_warning_on_return_false)
      ActiveSupport::Callbacks.halt_and_display_warning_on_return_false = false
    end
    NoBrainer.rails5? ? options : options.merge(:terminator => proc { false })
  end

  included do
    extend ActiveModel::Callbacks

    define_model_callbacks :initialize, :create, :update, :save, :destroy, NoBrainer::Document::Callbacks.define_callbacks_options
    define_model_callbacks :find, NoBrainer::Document::Callbacks.define_callbacks_options(:only => [:after])
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
