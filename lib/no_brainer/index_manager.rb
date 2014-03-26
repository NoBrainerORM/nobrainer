module NoBrainer::IndexManager
  def self.update_indexes(options={})
    NoBrainer::Document.all.each { |model| model.perform_update_indexes(options.merge(:wait => false)) }
    unless options[:wait] == false
      NoBrainer::Document.all.each { |model| model.wait_for_index(nil) }
    end
  end
end
