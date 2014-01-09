module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    field :created_at, :type => Time
    field :updated_at, :type => Time

    before_create { self.created_at = Time.now }
    before_save   { self.updated_at = Time.now }
  end
end
