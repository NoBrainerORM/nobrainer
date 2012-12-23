require 'active_model'

class NoBrainer::Base
  extend ActiveSupport::Autoload
  autoload :Persistance
  autoload :Fields
  autoload :Scope
  autoload :Core
  autoload :Validation

  include Persistance
  include Fields
  include Scope
  include Core
  include Validation
end
