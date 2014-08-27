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

  def autoload_and_include(*constants)
    constants.each { |constant| autoload constant }
    constants.each { |constant| include const_get(constant) }
  end

  def eager_autoload_and_include(*constants)
    eager_autoload(*constants)
    constants.each { |constant| include const_get(constant) }
  end
end
