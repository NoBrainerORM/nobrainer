class NoBrainer::Document::Association::HasManyThrough
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_OPTIONS = [:through]
    include NoBrainer::Document::Association::Core::Metadata

    def through_association_name
      options[:through].to_sym
    end

    def through_association
      owner_model.association_metadata[through_association_name] or
        raise "#{through_association_name} association not found"
    end

    def eager_load(docs, criteria=nil)
      NoBrainer::Document::Association::EagerLoader.new
        .eager_load_association(through_association.eager_load(docs), target_name, criteria)
    end

    def target_model
      # Not used in our code, but useful for 3rd party plugins (see #114)
      meta = through_association.target_model.association_metadata
      association = meta[target_name.to_sym] || meta[target_name.to_s.singularize.to_sym]
      association.target_model
    end
  end

  def read
    # TODO implement joins
    @targets ||= metadata.eager_load([owner]).freeze
  end

  def write(new_children)
    raise "You can't assign #{target_name}"
  end
end
