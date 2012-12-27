module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :Id, :InjectionLayer, :Persistance, :Attributes,
                       :Serialization, :Selection, :Validation, :Relation
end
