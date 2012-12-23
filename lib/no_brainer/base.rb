require 'active_model'

class NoBrainer::Base
  extend ActiveSupport::Autoload

  def self.load_and_include(mod)
    autoload mod
    include const_get mod
  end

  load_and_include :Persistance
  load_and_include :Fields
  load_and_include :Scope
  load_and_include :Core
  load_and_include :Validation
end
