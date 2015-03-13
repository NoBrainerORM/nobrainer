class NoBrainer::Document::Association::BelongsTo
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_OPTIONS = [:primary_key, :foreign_key, :class_name, :foreign_key_store_as, :index, :validates, :required,
                     :polymorphic]
    include NoBrainer::Document::Association::Core::Metadata
    extend NoBrainer::Document::Association::EagerLoader::Generic

    def foreign_key
      # TODO test :foreign_key
      options[:foreign_key].try(:to_sym) || :"#{target_name}_#{primary_key}"
    end

    def primary_key
      # TODO test :primary_key
      options[:primary_key].try(:to_sym) || target_model.pk_name
    end

    def target_model
      # TODO test :class_name
      (options[:class_name] || target_name.to_s.camelize).constantize
    end

    def base_criteria
      target_model.unscoped
    end

    def hook
      super

      # TODO It would be good to set the type we want to work with, but because
      # the target class is eager loaded, we are not doing it.
      # This would have the effect of loading all the models because they
      # are likely to be related to each other. So we don't know the type
      # of the primary key of the target.
      owner_model.field(foreign_key, :store_as => options[:foreign_key_store_as], :index => options[:index])
      owner_model.validates(target_name, :presence => options[:required]) if options[:required]
      owner_model.validates(target_name, options[:validates]) if options[:validates]

      delegate("#{foreign_key}=", :assign_foreign_key, :call_super => true)
      delegate("#{target_name}_changed?", "#{foreign_key}_changed?", :to => :self)
      add_callback_for(:after_validation)
    end

    eager_load_with :owner_key => ->{ foreign_key }, :target_key => ->{ primary_key }
  end

  # Note:
  # @target_container is an array to distinguish the following cases:
  # * target is not loaded, but perhaps present in the db.
  # * we already tried to load target, but it wasn't present in the db.

  def assign_foreign_key(value)
    @target_container = nil
  end

  def read
    return target if loaded?

    if fk = owner.read_attribute(foreign_key)
      preload(target_model.unscoped.where(primary_key => fk).first)
    end
  end

  def write(target)
    assert_target_type(target)
    owner.write_attribute(foreign_key, target.try(:pk_value))
    preload(target)
  end

  def preload(targets)
    @target_container = [*targets] # the * is for the generic eager loading code
    target
  end

  def target
    @target_container.first
  end

  def loaded?
    !@target_container.nil?
  end

  def after_validation_callback
    if loaded? && target && !target.persisted?
      raise NoBrainer::Error::AssociationNotPersisted.new("#{target_name} must be saved first")
    end
  end
end
