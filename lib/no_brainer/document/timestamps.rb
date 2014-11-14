module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    field :created_at, :type => Time
    field :updated_at, :type => Time
  end

  def _create(options={})
    now = Time.now
    self.created_at = now unless created_at_changed?
    self.updated_at = now unless updated_at_changed?
    super
  end

  def _update(attrs)
    self.updated_at = Time.now unless updated_at_changed?
    super(attrs.merge('updated_at' => @_attributes['updated_at']))
  end
end
