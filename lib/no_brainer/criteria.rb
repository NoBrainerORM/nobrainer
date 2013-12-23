class NoBrainer::Criteria
  # The disctinction between Chainable and Termination is purely cosmetic.
  module Chainable
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Core, :Scope, :Raw, :Where, :OrderBy, :Limit
  end

  module Termination
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Count, :Delete, :Enumerable, :EagerLoading, :First,
                         :Inc, :Update, :Cache
  end

  include Chainable
  include Termination
end
