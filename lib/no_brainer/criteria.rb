require 'rethinkdb'

class NoBrainer::Criteria
  # The disctinction between Chainable and Termination is purely cosmetic.
  module Chainable
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Core, :Scope, :Raw, :AfterFind, :Where, :OrderBy, :Limit
  end

  module Termination
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Count, :Delete, :Enumerable, :First, :Preload,
                         :Inc, :Update, :Cache
  end

  include Chainable
  include Termination
end
