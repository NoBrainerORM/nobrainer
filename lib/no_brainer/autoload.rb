module NoBrainer::Autoload
  include ActiveSupport::Autoload

  def self.extended(base)
    ActiveSupport::Autoload.send(:extended, base)
  end

  def autoload(*constants)
    constants.each { |constant| super(constant) }
  end

  def eager_autoload(*constants)
    super() { autoload(*constants) }
  end

  def eager_load!
    if NoBrainer.rails71?
      if @_eagerloaded_constants
        @_eagerloaded_constants.map { |const_name| const_get(const_name) }
                               .each { |c| c.eager_load! if c.respond_to?(:eager_load!) }
        @_eagerloaded_constants = nil
      end
    else
      super
      @_autoloads.keys.map  { |c| const_get(c) }
                      .each { |c| c.eager_load! if c.respond_to?(:eager_load!) }
    end
  end

  def autoload_and_include(*constants)
    eager_autoload(*constants)
    constants.each { |constant| include const_get(constant) }
  end
end
