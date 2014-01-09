require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :Scope, :Raw, :AfterFind, :Where, :OrderBy, :Limit,
                       :Count, :Delete, :Enumerable, :First, :Preload, :Inc,
                       :Update, :Cache
end
