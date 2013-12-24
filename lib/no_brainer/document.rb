module NoBrainer::Document
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload_and_include :Core, :StoreIn, :InjectionLayer, :Attributes, :Persistance, :Dirty,
                       :Id, :Relation, :Serialization, :Criteria, :Validation,
                       :Polymorphic, :Index

  autoload :DynamicAttributes, :Timestamps

  included do
    include Timestamps if NoBrainer::Config.auto_include_timestamps
  end

  singleton_class.delegate :all, :to => Core
end
