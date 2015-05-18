require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Readonly,
                       :Persistance, :Callbacks, :Validation, :Types, :Dirty, :PrimaryKey,
                       :Association, :Serialization, :Criteria, :Polymorphic, :Index, :Aliases,
                       :MissingAttributes, :LazyFetch, :AtomicOps

  autoload :DynamicAttributes, :Timestamps

  included { define_default_pk }

  singleton_class.delegate :all, :to => Core
end
