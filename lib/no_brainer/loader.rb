module NoBrainer::Loader
  def self.cleanup
    NoBrainer::Document::Core._all.clear
  end
end
