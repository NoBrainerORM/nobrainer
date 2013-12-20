class NoBrainer::Document::Relation::BelongsTo
  class Metadata
    include NoBrainer::Document::Relation::Core::Metadata

    def foreign_key
      # TODO test :foreign_key
      @foreign_key ||= options[:foreign_key] || :"#{rhs_name}_id"
    end

    def rhs_klass
      # TODO test :class_name
      @rhs_klass ||= (options[:class_name] || rhs_name.to_s.camelize).constantize
    end

    def hook
      # TODO yell when some options are not recognized
      @foreign_key = nil
      @rhs_klass = nil

      lhs_klass.field foreign_key
      delegate("#{foreign_key}=", :assign_foreign_key, :call_super => true)
      delegate("#{rhs_name}=", :write)
      delegate("#{rhs_name}", :read)
    end
  end

  include NoBrainer::Document::Relation::Core
  delegate :foreign_key, :rhs_klass, :to => :metadata

  def assign_foreign_key(value)
    @parent = nil
  end

  def read
    if fk = instance.read_attribute(foreign_key)
      @parent ||= rhs_klass.find(fk)
    end
  end

  def write(new_parent)
    new_parent.save! if new_parent && !new_parent.persisted?
    instance.write_attribute(foreign_key, new_parent.try(:id))
    @parent = new_parent
  end
end
