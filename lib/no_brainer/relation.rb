module NoBrainer::Relation
  extend ActiveSupport::Autoload

  # you also want to check NoBrainer::Document::Relation
  autoload :BelongsTo
  autoload :HasMany
end
