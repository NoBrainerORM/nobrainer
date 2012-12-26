class NoBrainer::Selection
  extend ActiveSupport::Autoload

  def self.load_and_include(mod)
    autoload mod
    include const_get mod
  end

  load_and_include :Core
  load_and_include :Count
  load_and_include :Delete
  load_and_include :Enumerable
  load_and_include :First
  load_and_include :Inc
  load_and_include :Limit
  load_and_include :OrderBy
  load_and_include :Update
  load_and_include :Where
end
