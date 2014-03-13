module NoBrainer::IndexManager
  def self.update_indexes(options={})
    NoBrainer::Document.all.each { |model| model.perform_update_indexes(options) }
  end
end
