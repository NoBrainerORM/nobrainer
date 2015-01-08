module NoBrainer::Criteria::Scope
  extend ActiveSupport::Concern

  included { criteria_option :use_default_scope, :merge_with => :set_scalar }

  def scoped
    chain(:use_default_scope => true)
  end

  def unscoped
    chain(:use_default_scope => false)
  end

  def respond_to?(name, include_private = false)
    super || self.model.respond_to?(name)
  end

  def method_missing(name, *args, &block)
    return super unless self.model.respond_to?(name)
    criteria = self.model.method(name).call(*args, &block)
    raise "#{name} did not return a criteria" unless criteria.is_a?(NoBrainer::Criteria)
    merge(criteria)
  end

  private

  def _apply_default_scope
    return self if @options[:use_default_scope] == false
    (model.default_scopes.map(&:call).compact + [self]).reduce(:merge)
  end

  module ClassMethods
    def _finalize_criteria(base)
      super.__send__(:_apply_default_scope)
    end
  end
end
