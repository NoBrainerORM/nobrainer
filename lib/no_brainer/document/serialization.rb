module NoBrainer::Document::Serialization
  extend ActiveSupport::Concern

  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON

  def read_attribute_for_serialization(*a, &b)
    read_attribute(*a, &b)
  end
end
