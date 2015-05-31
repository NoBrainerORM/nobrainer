require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :Run, :Raw, :Scope, :AfterFind, :Where, :OrderBy,
                       :Limit, :Pluck, :Count, :Delete, :Enumerable, :First,
                       :Find, :Aggregate, :EagerLoad, :Update, :Cache, :Index,
                       :Extend
end
