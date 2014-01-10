module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    field :created_at, :type => Time
    field :updated_at, :type => Time
  end

  def _create(options={})
    self.created_at = self.updated_at = Time.now
    super
  end

  def _update(attrs)
    self.updated_at = Time.now
    super(attrs.merge('updated_at' => @_attributes['updated_at']))
  end
end
