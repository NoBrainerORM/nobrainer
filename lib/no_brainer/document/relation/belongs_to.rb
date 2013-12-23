class NoBrainer::Document::Relation::BelongsTo
  include NoBrainer::Document::Relation::Core

  class Metadata
    include NoBrainer::Document::Relation::Core::Metadata

    def foreign_key
      # TODO test :foreign_key
      @foreign_key ||= options[:foreign_key].try(:to_sym) || :"#{target_name}_id"
    end

    def target_klass
      # TODO test :class_name
      @target_klass ||= (options[:class_name] || target_name.to_s.camelize).constantize
    end

    def hook
      super
      @foreign_key = nil
      @target_klass = nil

      options.assert_valid_keys(:foreign_key, :class_name, :index)

      owner_klass.field foreign_key, :index => options[:index]

      delegate("#{foreign_key}=", :assign_foreign_key, :call_super => true)

      if !@added_before_save_callback
        metadata = self
        owner_klass.before_save { relation(metadata).before_save_callback }
        @added_before_save_callback = true
      end
    end

    def eager_load(docs)
      docs_fks = Hash[docs.map { |doc| [doc, doc.read_attribute(foreign_key)] }]
      fks = docs_fks.values.compact.uniq
      fk_targets = Hash[target_klass.where(:id.in => fks).map { |doc| [doc.id, doc] }]
      docs_fks.each { |doc, fk| doc.relation(self)._write(fk_targets[fk]) if fk_targets[fk] }
    end
  end

  def assign_foreign_key(value)
    @parent = nil
  end

  def read
    return @parent if @parent && NoBrainer::Config.cache_documents
    if fk = instance.read_attribute(foreign_key)
      @parent = target_klass.find(fk)
    end
  end

  def _write(new_parent)
    @parent = new_parent
  end

  def write(new_parent)
    assert_target_type(new_parent)
    instance.write_attribute(foreign_key, new_parent.try(:id))
    _write(new_parent)
  end

  def before_save_callback
    if @parent
      raise NoBrainer::Error::ParentNotSaved.new("#{target_name} must be saved first") unless @parent.persisted?
    end
    true
  end
end
