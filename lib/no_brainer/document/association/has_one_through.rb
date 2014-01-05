class NoBrainer::Document::Association::HasOneThrough < NoBrainer::Document::Association::HasManyThrough
  class Metadata < NoBrainer::Document::Association::HasManyThrough::Metadata
  end

  def read
    targets = super
    NoBrainer.logger.warn "#{owner} has more than one #{target_name}" if targets.size > 1
    targets.first
  end
end
