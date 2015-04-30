class NoBrainer::Document::Association::HasOne < NoBrainer::Document::Association::HasMany
  class Metadata < NoBrainer::Document::Association::HasMany::Metadata
    def target_model
      get_model_by_name(options[:class_name] || target_name.to_s.camelize)
    end
  end

  def read
    targets = target_criteria.to_a # to load the cache
    NoBrainer.logger.warn "#{owner} has more than one #{target_name}" if targets.size > 1
    targets.first
  end
end
