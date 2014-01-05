class NoBrainer::Document::Association::HasMany
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_OPTIONS = [:foreign_key, :class_name, :dependent]
    include NoBrainer::Document::Association::Core::Metadata
    extend NoBrainer::Document::Association::EagerLoader::Generic

    def foreign_key
      # TODO test :foreign_key
      options[:foreign_key].try(:to_sym) || owner_klass.name.foreign_key.to_sym
    end

    def target_klass
      # TODO test :class_name
      (options[:class_name] || target_name.to_s.singularize.camelize).constantize
    end

    def inverses
      # We can always infer the inverse association of a has_many relationship,
      # because a belongs_to association cannot have a scope applied on the
      # selector.
      # XXX Without caching, this is going to get CPU intensive quickly, but
      # caching is hard (rails console reload, etc.).
      target_klass.association_metadata.values.select do |assoc|
        assoc.is_a?(NoBrainer::Document::Association::BelongsTo::Metadata) and
        assoc.foreign_key == self.foreign_key                              and
        assoc.target_klass.root_class == owner_klass.root_class
      end
    end

    def hook
      super
      add_callback_for(:before_destroy) if options[:dependent]
    end

    eager_load_with :owner_key => ->{ :id }, :target_key => ->{ foreign_key }
  end

  def target_criteria
    @target_criteria ||= target_klass.where(foreign_key => owner.id)
                                     ._after_instantiate(set_inverse_proc)
  end

  def read
    target_criteria
  end

  def write(new_children)
    raise "You can't assign the array of #{target_name}. " +
          "Instead, you must modify delete and create #{target_klass} manually."
  end

  def loaded?
    target_criteria.cached?
  end

  def preload(new_targets)
    set_inverses_of(new_targets)
    target_criteria._override_cache(new_targets)
  end

  def set_inverses_of(new_targets)
    @inverses ||= metadata.inverses
    return if @inverses.blank?

    new_targets.each do |target|
      # We don't care if target is a parent class where the inverse association
      # is defined, we set the association regardless.
      # The user won't be able to access it since the association accessors are
      # not defined on the parent class.
      @inverses.each { |inverse| target.association(inverse).preload(self.owner) }
    end
  end

  def set_inverse_proc
    lambda { |target| set_inverses_of([target]) if target.is_a?(NoBrainer::Document) }
  end

  def before_destroy_callback
    criteria = target_criteria.unscoped.without_cache
    case metadata.options[:dependent]
    when nil       then
    when :destroy  then criteria.destroy_all
    when :delete   then criteria.delete_all
    when :nullify  then criteria.update_all(foreign_key => nil)
    when :restrict then raise NoBrainer::Error::ChildrenExist unless criteria.count.zero?
    else raise "Unrecognized dependent option: #{metadata.options[:dependent]}"
    end
  end
end
