require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Readonly,
                       :Validation, :Persistance, :Types, :Uniqueness, :Callbacks, :Dirty, :Id,
                       :Association, :Serialization, :Criteria, :Polymorphic, :Index, :Aliases,
                       :MissingAttributes

  autoload :DynamicAttributes, :Timestamps

  included { define_default_pk }

  singleton_class.delegate :all, :to => Core
end
