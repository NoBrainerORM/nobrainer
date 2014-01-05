class NoBrainer::Document::Association::BelongsTo
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_BELONGS_TO_OPTIONS = [:foreign_key, :class_name, :index]
    include NoBrainer::Document::Association::Core::Metadata
    extend NoBrainer::Document::Association::EagerLoader::Generic

    def foreign_key
      # TODO test :foreign_key
      options[:foreign_key].try(:to_sym) || :"#{target_name}_id"
    end

    def target_klass
      # TODO test :class_name
      (options[:class_name] || target_name.to_s.camelize).constantize
    end

    def hook
      super
      options.assert_valid_keys(*VALID_BELONGS_TO_OPTIONS)

      owner_klass.field foreign_key, :index => options[:index]
      delegate("#{foreign_key}=", :assign_foreign_key, :call_super => true)
      add_callback_for(:after_validation)
      # TODO test if we are not overstepping on another foreign_key
    end

    eager_load_with :owner_key => ->{ foreign_key }, :target_key => ->{ :id },
                    :unscoped => true
  end

  # Note:
  # @target_container is an array to distinguish the following cases:
  # * target is not loaded, but perhaps present in the db.
  # * we already tried to load target, but it wasn't present in the db.

  def assign_foreign_key(value)
    @target_container = nil
  end

  def read
    return @target_container.first if loaded?

    if fk = owner.read_attribute(foreign_key)
      preload(target_klass.find(fk))
    end
  end

  def write(target)
    assert_target_type(target)
    owner.write_attribute(foreign_key, target.try(:id))
    preload(target)
  end

  def preload(target)
    @target_container = [*target] # the * is for the generic eager loading code
    @target_container.first
  end

  def loaded?
    !@target_container.nil?
  end

  def after_validation_callback
    if loaded? && @target_container.first && !@target_container.first.persisted?
      raise NoBrainer::Error::AssociationNotSaved.new("#{target_name} must be saved first")
    end
  end
end
