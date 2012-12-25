require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Autoload
  extend ActiveSupport::Concern

  def self.load_and_include(mod)
    autoload mod
    include const_get mod
  end

  load_and_include :Core
  load_and_include :Id
  load_and_include :InjectionLayer
  load_and_include :Persistance
  load_and_include :Attributes
  load_and_include :Selection
  load_and_include :Validation
  load_and_include :Relation
end
