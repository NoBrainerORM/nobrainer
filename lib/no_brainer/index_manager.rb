module NoBrainer::IndexManager
  def self.update_indexes(options={})
    Rails.application.eager_load! if defined?(Rails)
    NoBrainer::Document.models.each { |model| model.perform_update_indexes(options) }
  end
end
