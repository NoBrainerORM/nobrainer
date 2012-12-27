module NoBrainer::Autoload
  include ActiveSupport::Autoload

  def autoload(*args)
    args.each { |mod| super mod }
  end

  def autoload_and_include(*mods)
    mods.each do |mod|
      autoload mod
      include const_get mod
    end
  end
end
