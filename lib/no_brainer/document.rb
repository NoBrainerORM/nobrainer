module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :InjectionLayer, :Attributes, :Persistance, :Dirty,
                       :Id, :Relation, :Serialization, :Criteria, :Validation,
                       :Polymorphic, :Timestamps, :Index

  autoload :DynamicAttributes

  singleton_class.delegate :models, :to => Core
end
