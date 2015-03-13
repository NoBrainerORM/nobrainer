class NoBrainer::Document::Association::HasMany
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_OPTIONS = [:primary_key, :foreign_key, :class_name, :dependent, :scope, :as]
    include NoBrainer::Document::Association::Core::Metadata
    extend NoBrainer::Document::Association::EagerLoader::Generic

    def foreign_key
      # TODO test :foreign_key
      if polymorphic?
        "#{polymorphic_target_association_name}_#{NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME}"
      else
        options[:foreign_key].try(:to_sym) || :"#{owner_model.name.underscore}_#{owner_model.pk_name}"
      end
    end

    def primary_key
      # TODO test :primary_key
      options[:primary_key].try(:to_sym) || target_model.pk_name
    end

    def target_model
      # TODO test :class_name
      (options[:class_name] || target_name.to_s.singularize.camelize).constantize
    end

    def polymorphic_target_association_name
      options[:as]
    end

    def polymorphic?
      not options[:as].nil?
    end

    def base_criteria
      options[:scope] ? target_model.instance_exec(&options[:scope]) : target_model.all
    end

    def inverses
      # We can always infer the inverse association of a has_many relationship,
      # because a belongs_to association cannot have a scope applied on the
      # selector.
      # XXX Without caching, this is going to get CPU intensive quickly, but
      # caching is hard (rails console reload, etc.).
      target_model.association_metadata.values.select do |assoc|
        assoc.is_a?(NoBrainer::Document::Association::BelongsToPolymorphic::Metadata) &&
          assoc.target_name == self.polymorphic_target_association_name \
        or
          assoc.is_a?(NoBrainer::Document::Association::BelongsTo::Metadata) &&
          assoc.foreign_key == self.foreign_key                              &&
          assoc.primary_key == self.primary_key                              &&
          assoc.target_model.root_class == owner_model.root_class
      end
    end

    def hook
      super

      if options[:scope]
        raise ":scope must be passed a lambda like this: `:scope => ->{ where(...) }'" unless options[:scope].is_a?(Proc)
        raise ":dependent and :scope cannot be used together" if options[:dependent]
      end

      if options[:dependent]
        unless [:destroy, :delete, :nullify, :restrict, nil].include?(options[:dependent])
          raise "Invalid dependent option: `#{options[:dependent].inspect}'. " +
                "Valid options are: :destroy, :delete, :nullify, or :restrict"
        end
        add_callback_for(:before_destroy)
      end
    end

    eager_load_with :owner_key => ->{ primary_key }, :target_key => ->{ foreign_key }
  end

  def target_criteria
    @target_criteria ||= base_criteria.where(foreign_key => owner.pk_value)
                                      .after_find(set_inverse_proc)
  end

  def read
    target_criteria
  end

  def write(new_children)
    raise "You can't assign `#{target_name}'. " \
          "Instead, you must modify delete and create `#{target_model}' manually."
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
      @inverses.each { |inverse| target.associations[inverse].preload(self.owner) }
    end
  end

  def set_inverse_proc
    ->(target){ set_inverses_of([target]) if target.is_a?(NoBrainer::Document) }
  end

  def before_destroy_callback
    criteria = target_criteria.unscoped.without_cache
    case metadata.options[:dependent]
    when :destroy  then criteria.destroy_all
    when :delete   then criteria.delete_all
    when :nullify  then criteria.update_all(foreign_key => nil)
    when :restrict then raise NoBrainer::Error::ChildrenExist unless criteria.count.zero?
    end
  end
end
