module NoBrainer::Loader
  include ActiveSupport::Autoload

  def autoload_and_include(*mods)
    mods.each do |mod|
      autoload mod
      include const_get mod
    end
  end

  def autoload_and_extend(*mods)
    mods.each do |mod|
      autoload mod
      extend const_get mod
    end
  end
  alias_method :use, :autoload_and_extend
end
