require 'rethinkdb'

class NoBrainer::Criteria
  extend NoBrainer::Autoload
  autoload_and_include :Core, :RunWith, :Raw, :AfterFind, :Where, :OrderBy,
                       :Limit, :Pluck, :Count, :Delete, :Enumerable, :First,
                       :Find, :Aggregate, :EagerLoad, :Update, :Cache, :Index,
                       :Extend, :Scope
end
