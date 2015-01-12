class NoBrainer::Document::Association::BelongsToPolymorphic < NoBrainer::Document::Association::BelongsTo
  class Metadata < NoBrainer::Document::Association::BelongsTo::Metadata
    def foreign_key
      options[:foreign_key].try(:to_sym) || "#{target_name}_#{NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME}"
    end

    def polymorphic_type_field
      :"#{target_name}_type"
    end

    def primary_key
      raise "Cannot statically determine primary key of polymorphic association '#{target_name}'"
    end

    def target_model
      raise "Cannot statically determine target model of polymorphic association '#{target_name}'"
    end

    def hook
      super
      owner_model.field(polymorphic_type_field, :index => options[:index])
    end
  end

  def target_model
    owner.read_attribute(polymorphic_type_field).constantize
  end

  def primary_key
    target_model.pk_name
  end

  def write(target)
    owner.write_attribute(foreign_key, target.try(:pk_value))
    owner.write_attribute(polymorphic_type_field, target.class.name)
    preload(target)
  end
end
