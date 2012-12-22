require 'active_model'

class NoBrainer::Base
  extend ActiveSupport::Autoload
  autoload :Persistance
  autoload :Fields
  autoload :Scope
  autoload :Core

  include Persistance
  include Fields
  include Scope
  include Core
end
