class NoBrainer::Document::Relation::HasMany
  include NoBrainer::Document::Relation::Core

  class Metadata
    include NoBrainer::Document::Relation::Core::Metadata

    def foreign_key
      # TODO test :foreign_key
      @foreign_key ||= options[:foreign_key].try(:to_sym) || :"#{owner_klass.name.underscore}_id"
    end

    def target_klass
      # TODO test :class_name
      @target_klass ||= (options[:class_name] || target_name.to_s.singularize.camelize).constantize
    end

    def hook
      super
      @foreign_key = nil
      @target_klass = nil

      options.assert_valid_keys(:foreign_key, :class_name, :dependent)

      if options[:dependent] && !@added_destroy_callback
        metadata = self
        owner_klass.before_destroy { relation(metadata).before_destroy_callback }
        @added_destroy_callback = true
      end
    end

    def eager_load(docs, criteria=nil)
      target_criteria = target_klass.all
      target_criteria = target_criteria.merge(criteria) if criteria
      docs_ids = Hash[docs.map { |doc| [doc, doc.id] }]
      fk_targets = target_criteria
        .where(foreign_key.in => docs_ids.values)
        .reduce({}) do |hash, doc|
          fk = doc.read_attribute(foreign_key)
          hash[fk] ||= []
          hash[fk] << doc
          hash
        end
      docs_ids.each { |doc, id| doc.relation(self)._write(fk_targets[id]) if fk_targets[id] }
      fk_targets.values.flatten(1)
    end
  end

  def children_criteria
    @children_criteria ||= target_klass.where(foreign_key => instance.id)
  end

  def read
    children_criteria
  end

  def write(new_children)
    raise "You can't assign the array of #{target_name}. Instead, you must modify delete and create #{target_klass} manually."
    # Because it's a huge mess when the target class has a default scope as
    # things get inconsistent very quickly.
  end

  def _write(new_children)
    children_criteria._override_cache(new_children)
  end

  def before_destroy_callback
    criteria = children_criteria.unscoped
    case metadata.options[:dependent]
    when nil       then
    when :destroy  then criteria.destroy_all
    when :delete   then criteria.delete_all
    when :nullify  then criteria.update_all(foreign_key => nil)
    when :restrict then raise NoBrainer::Error::ChildrenExist unless criteria.count.zero?
    else raise "Unrecognized dependent option: #{metadata.options[:dependent]}"
    end
    true
  end
end
