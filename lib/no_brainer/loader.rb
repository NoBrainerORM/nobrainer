module NoBrainer::Loader
  def self.cleanup
    NoBrainer::Document.models.clear
  end
end
