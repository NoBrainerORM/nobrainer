module NoBrainer::Criteria::Scope
  extend ActiveSupport::Concern

  included { attr_accessor :use_default_scope }

  def scoped
    chain { |criteria| criteria.use_default_scope = true }
  end

  def unscoped
    chain { |criteria| criteria.use_default_scope = false }
  end

  def merge!(criteria, options={})
    super
    self.use_default_scope = criteria.use_default_scope unless criteria.use_default_scope.nil?
    self
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

  def should_apply_default_scope?
    model.default_scope_proc && use_default_scope != false
  end

  def _apply_default_scope
    return unless should_apply_default_scope?
    criteria = model.default_scope_proc.call
    raise "Mixing model issue. Contact developer." if [criteria.model, self.model].compact.uniq.size == 2
    criteria.merge(self)
  end

  module ClassMethods
    def _finalize_criteria(base)
      criteria = super
      criteria.__send__(:_apply_default_scope) || criteria
    end
  end
end
