module NoBrainer::Selection::Scope
  def respond_to?(name, include_private = false)
    super || klass.respond_to?(name)
  end

  # TODO Make something a bit more efficent
  def method_missing(name, *args, &block)
    return super unless klass.respond_to?(name)
    klass.method(name).call(*args, &block)
  end
end
