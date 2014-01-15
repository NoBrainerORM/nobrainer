module NoBrainer::Document::Callbacks
  extend ActiveSupport::Concern

  def self.terminator
    if Gem.loaded_specs['activesupport'].version >= Gem::Version.new('4.1')
      lambda { false }
    else
      'false'
    end
  end

  included do
    extend ActiveModel::Callbacks

    define_model_callbacks :initialize, :create, :update, :save, :destroy, :terminator => NoBrainer::Document::Callbacks.terminator
    define_model_callbacks :find, :only => [:after], :terminator => NoBrainer::Document::Callbacks.terminator
  end

  def initialize(*args, &block)
    run_callbacks(:initialize) { _initialize(*args); true }
  end

  def _create(*args, &block)
    run_callbacks(:create) { super }
  end

  def _update_only_changed_attrs(*args, &block)
    run_callbacks(:update) { super }
  end

  def save(*args, &block)
    run_callbacks(:save) { super }
  end

  def destroy(*args, &block)
    run_callbacks(:destroy) { super }
  end
end
