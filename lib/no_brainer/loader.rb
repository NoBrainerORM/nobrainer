module NoBrainer::Loader
  def self.cleanup
    NoBrainer::Document.all.clear
  end
end
