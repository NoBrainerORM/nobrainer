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
    super || self.klass.respond_to?(name)
  end

  def method_missing(name, *args, &block)
    return super unless self.klass.respond_to?(name)
    criteria = self.klass.method(name).call(*args, &block)
    raise "#{name} did not return a criteria" unless criteria.is_a?(NoBrainer::Criteria)
    merge(criteria)
  end

  private

  def should_apply_default_scope?
    klass.default_scope_proc && use_default_scope != false
  end

  def with_default_scope_applied
    if should_apply_default_scope?
      # XXX If default_scope.class != self.class, oops
      klass.default_scope_proc.call.merge(self).unscoped
    else
      self
    end
  end
end
