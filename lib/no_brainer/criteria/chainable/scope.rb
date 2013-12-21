module NoBrainer::Criteria::Chainable::Scope
  extend ActiveSupport::Concern

  included { attr_accessor :use_default_scope }

  def scoped
    chain { |criteria| criteria.use_default_scope = true }
  end

  def unscoped
    chain { |criteria| criteria.use_default_scope = false }
  end

  def merge!(criteria)
    super
    self.use_default_scope = criteria.use_default_scope unless criteria.use_default_scope.nil?
  end

  def respond_to?(name, include_private = false)
    super || self.klass.respond_to?(name)
  end

  def method_missing(name, *args, &block)
    return super unless self.klass.respond_to?(name)
    merge(self.klass.method(name).call(*args, &block))
  end

  private

  def compile_criteria
    criteria = super
    if klass.default_scope_proc && use_default_scope != false
      criteria = criteria.merge(klass.default_scope_proc.call)
    end
    criteria
  end
end
