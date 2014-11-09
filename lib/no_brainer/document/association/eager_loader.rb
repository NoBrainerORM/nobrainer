class NoBrainer::Document::Association::EagerLoader
  module Generic
    # Used in associations to declare generic eager loading capabilities
    # The association should implement loaded? and preload.
    def eager_load_with(options={})
      define_method(:eager_load) do |docs, additional_criteria=nil|
        owner_key  = instance_exec(&options[:owner_key])
        target_key = instance_exec(&options[:target_key])

        criteria = target_model.all
        criteria = criteria.merge(additional_criteria) if additional_criteria
        criteria = criteria.unscoped if options[:unscoped]

        unloaded_docs = docs.reject { |doc| doc.associations[self].loaded? }

        owner_keys = unloaded_docs.map(&owner_key).compact.uniq
        if owner_keys.present?
          targets = criteria.where(target_key.in => owner_keys)
                            .map { |target| [target.read_attribute(target_key), target] }
                            .each_with_object(Hash.new { |k,v| k[v] = [] }) { |(k,v),h| h[k] << v }

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
    # TODO test the singularize thingy.
    association = meta[association_name.to_sym] || meta[association_name.to_s.singularize.to_sym]
    raise "Unknown association #{association_name}" unless association
    association.eager_load(docs, criteria)
  end

  def eager_load(docs, preloads)
    case preloads
    when Hash  then preloads.each do |k,v|
      if v.is_a?(NoBrainer::Criteria)
        v = v.dup
        nested_preloads, v.options[:preload] = v.options[:preload], []
        eager_load(eager_load_association(docs, k, v), nested_preloads)
      else
        eager_load(eager_load_association(docs, k), v)
      end
    end
    when Array then preloads.each { |v| eager_load(docs, v) }
    when nil then;
    else eager_load_association(docs, preloads) # String and Symbol
    end
    true
  end
end
