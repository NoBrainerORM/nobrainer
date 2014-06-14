require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Readonly, :Validation, :Types,
                       :Persistance, :Uniqueness, :Callbacks, :Dirty, :Id, :Association, :Serialization,
                       :Criteria, :Polymorphic, :Index

  autoload :DynamicAttributes, :Timestamps

  included { define_default_pk }

  singleton_class.delegate :all, :to => Core
end
