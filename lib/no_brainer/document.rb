module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :InjectionLayer, :Attributes, :Id, :Relation,
                       :Persistance, :Serialization, :Selection, :Validation, :Polymorphic,
                       :Timestamps
end
