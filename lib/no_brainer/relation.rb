module NoBrainer::Relation
  extend NoBrainer::Autoload

  autoload :BelongsTo, :HasMany
  # you also want to check NoBrainer::Document::Relation
end
