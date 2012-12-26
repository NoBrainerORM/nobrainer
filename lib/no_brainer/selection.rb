class NoBrainer::Selection
  extend NoBrainer::Loader

  autoload_and_include :Core, :Count, :Delete, :Enumerable, :First, :Inc,
                       :Limit, :OrderBy, :Update, :Where
end
