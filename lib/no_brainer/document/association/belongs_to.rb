class NoBrainer::Document::Association::BelongsTo
  include NoBrainer::Document::Association::Core

  class Metadata
    VALID_BELONGS_TO_OPTIONS = [:foreign_key, :class_name, :index]
    include NoBrainer::Document::Association::Core::Metadata

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
    end

    def eager_load(docs, criteria=nil)
      target_criteria = target_klass.all
      target_criteria = target_criteria.merge(criteria) if criteria
      docs_fks = Hash[docs.map { |doc| [doc, doc.read_attribute(foreign_key)] }]
      fks = docs_fks.values.compact.uniq
      fk_targets = Hash[target_criteria.where(:id.in => fks).map { |doc| [doc.id, doc] }]
      docs_fks.each { |doc, fk| doc.association(self)._write(fk_targets[fk]) if fk_targets[fk] }
      fk_targets.values
    end
  end

  def assign_foreign_key(value)
    @target = nil
  end

  def read
    return @target if @target && NoBrainer::Config.cache_documents
    if fk = instance.read_attribute(foreign_key)
      @target = target_klass.find(fk)
    end
  end

  def _write(target)
    @target = target
  end

  def write(target)
    assert_target_type(target)
    instance.write_attribute(foreign_key, target.try(:id))
    _write(target)
  end

  def after_validation_callback
    if @target && !@target.persisted?
      raise NoBrainer::Error::AssociationNotSaved.new("#{target_name} must be saved first")
    end
  end
end
