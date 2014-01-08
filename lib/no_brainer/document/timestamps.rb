module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    class_attribute :timestamps_disabled

    self.field :created_at, :type => Time
    self.field :updated_at, :type => Time

    before_create { self.created_at = Time.now unless self.timestamps_disabled }
    before_save   { self.updated_at = Time.now unless self.timestamps_disabled }
  end

  module ClassMethods
    def disable_timestamps
      self.timestamps_disabled = true
      self.remove_field :created_at
      self.remove_field :updated_at
    end
  end
end
