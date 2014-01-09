module NoBrainer::Document::Timestamps
  extend ActiveSupport::Concern

  included do
    field :created_at, :type => Time
    field :updated_at, :type => Time

    before_create { self.created_at = self.updated_at = Time.now }
    # Not using the before_update callback as it would mess
    # with the dirty tracking. We want to bypass the database
    # call if nothing has changed.
  end

  def _update_changed_attributes(changed_attrs)
    self.updated_at = Time.now
    changed_attrs['updated_at'] = @_attributes['updated_at']
    super
  end
end
