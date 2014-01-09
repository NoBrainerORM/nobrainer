module NoBrainer::Document::Serialization
  extend ActiveSupport::Concern

  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON

  included { self.include_root_in_json = false }
end
