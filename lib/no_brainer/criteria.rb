class NoBrainer::Criteria
  module Chainable
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Core, :Scope, :Where, :OrderBy, :Limit
  end

  module Termination
    extend NoBrainer::Autoload
    extend ActiveSupport::Concern
    autoload_and_include :Count, :Delete, :Enumerable, :First, :Inc, :Update
  end

  include Chainable
  include Termination
end
