require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Validation, :Types,
                       :Persistance, :Callbacks, :Dirty, :Id, :Association, :Serialization,
                       :Criteria, :Polymorphic, :Index

  autoload :DynamicAttributes, :Timestamps

  singleton_class.delegate :all, :to => Core
end
