require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :Run, :Raw, :Scope, :AfterFind, :Where, :OrderBy,
                       :Limit, :Pluck, :Count, :Delete, :Enumerable, :Find,
                       :First, :FirstOrCreate, :Aggregate, :EagerLoad, :Update,
                       :Cache, :Index, :Extend
end
