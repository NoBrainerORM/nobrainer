require 'active_model'

module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :TableConfig, :InjectionLayer, :Attributes, :Readonly,
                       :Persistance, :Callbacks, :Validation, :Types, :Dirty, :PrimaryKey,
                       :Association, :Serialization, :Criteria, :Polymorphic, :Index, :Aliases,
                       :MissingAttributes, :LazyFetch, :AtomicOps, :VirtualAttributes, :Reflections

  autoload :DynamicAttributes, :Timestamps

  included { define_default_pk }

  singleton_class.delegate :all, :to => Core
  singleton_class.delegate :reflect_on_association, :to => Core

  module ClassMethods
    def foo
      "OI"
    end
  endzz
end
