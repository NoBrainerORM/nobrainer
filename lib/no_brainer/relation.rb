module NoBrainer::Relation
  extend ActiveSupport::Autoload

  # you also want to check NoBrainer::Base::Relation
  autoload :BelongsTo
  autoload :HasMany
end
