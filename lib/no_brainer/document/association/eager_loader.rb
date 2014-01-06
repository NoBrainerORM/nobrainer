class NoBrainer::Document::Association::EagerLoader
  module Generic
    # Used in associations to declare generic eager loading capabilities
    # The association should implement loaded? and preload.
    def eager_load_with(options={})
      define_method(:eager_load) do |docs, additional_criteria=nil|
        owner_key  = instance_exec(&options[:owner_key])
        target_key = instance_exec(&options[:target_key])

        criteria = target_klass.all
        criteria = criteria.merge(additional_criteria) if additional_criteria
        criteria = criteria.unscoped if options[:unscoped]

        unloaded_docs = docs.reject { |doc| doc.associations[self].loaded? }

        owner_keys = unloaded_docs.map(&owner_key).compact.uniq
        if owner_keys.present?
          targets = criteria.where(target_key.in => owner_keys)
                            .map { |target| [target.read_attribute(target_key), target] }
                            .reduce(Hash.new { |k,v| k[v] = [] }) { |h,(k,v)| h[k] << v; h }

          unloaded_docs.each do |doc|
            doc_targets = targets[doc.read_attribute(owner_key)]
            doc.associations[self].preload(doc_targets)
          end
        end

        docs.map { |doc| doc.associations[self].read }.flatten.compact.uniq
      end
    end
  end

  def eager_load_association(docs, association_name, criteria=nil)
    docs = docs.compact
    return [] if docs.empty?
    meta = docs.first.root_class.association_metadata
    association = meta[association_name.to_sym] || meta[association_name.to_s.singularize.to_sym]
    raise "Unknown association #{association_name}" unless association
    association.eager_load(docs, criteria)
  end

  def eager_load(docs, includes)
    case includes
    when Hash  then includes.each do |k,v|
      if v.is_a?(NoBrainer::Criteria)
        v = v.dup
        nested_includes, v._includes = v._includes, []
        eager_load(eager_load_association(docs, k, v), nested_includes)
      else
        eager_load(eager_load_association(docs, k), v)
      end
    end
    when Array then includes.each { |v| eager_load(docs, v) }
    else eager_load_association(docs, includes)
    end
    true
  end
end
