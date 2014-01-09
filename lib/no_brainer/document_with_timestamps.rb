module NoBrainer::DocumentWithTimestamps
  extend ActiveSupport::Concern

  include NoBrainer::Document
  include NoBrainer::Document::Timestamps
end
