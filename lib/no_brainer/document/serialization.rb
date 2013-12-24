module NoBrainer::Document::Serialization
  extend ActiveSupport::Concern

  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  included { self.include_root_in_json = NoBrainer::Config.include_root_in_json }
end
