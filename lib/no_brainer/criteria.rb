require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :Run, :Raw, :VirtualAttributes, :Scope,
                       :AfterFind, :Where, :OrderBy, :Limit, :Pluck, :Count,
                       :Delete, :Enumerable, :Find, :First, :FirstOrCreate,
                       :Changes, :Aggregate, :EagerLoad, :Update, :Cache,
                       :Index, :Extend, :Join
end
