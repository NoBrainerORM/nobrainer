module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Persistance, :Dirty,
                       :Id, :Relation, :Serialization, :Criteria, :Validation,
                       :Polymorphic, :Timestamps, :Index

  autoload :DynamicAttributes

  singleton_class.delegate :all, :to => Core
end
