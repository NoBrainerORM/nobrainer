module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    self.field :created_at, :type => Time
    self.field :updated_at, :type => Time

    before_create { self.created_at = Time.now if self.respond_to?(:created_at=) }
    before_save   { self.updated_at = Time.now if self.respond_to?(:updated_at=) }
  end

  module ClassMethods
    def disable_timestamps
      self.remove_field :created_at
      self.remove_field :updated_at
    end
  end
end
