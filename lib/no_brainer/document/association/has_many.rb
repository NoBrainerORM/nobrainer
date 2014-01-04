class NoBrainer::Document::Association::HasMany
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_HAS_MANY_OPTIONS = [:foreign_key, :class_name, :dependent]
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

    def hook
      super
      options.assert_valid_keys(*VALID_HAS_MANY_OPTIONS)
      add_callback_for(:before_destroy)
    end

    eager_load_with :owner_key => ->{ :id }, :target_key => ->{ foreign_key }
  end

  def target_criteria
    @target_criteria ||= target_klass.where(foreign_key => instance.id)
  end

  def read
    target_criteria
  end

  def write(new_children)
    raise "You can't assign the array of #{target_name}. Instead, you must modify delete and create #{target_klass} manually."
  end

  def loaded?
    target_criteria.cached?
  end

  def preload(new_children)
    target_criteria._override_cache(new_children)
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
