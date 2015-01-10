require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :Raw, :AfterFind, :Where, :OrderBy, :Limit,
                       :Pluck, :Count, :Delete, :Enumerable, :First, :Aggregate,
                       :EagerLoad, :Update, :Cache, :Index, :Extend, :Scope
end
