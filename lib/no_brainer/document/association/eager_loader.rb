# frozen_string_literal: true

module NoBrainer::Document::Association::EagerLoader
  extend self

  module Generic
    # Used in associations to declare generic eager loading capabilities
    # The association should implement loaded?, preload,
    # eager_load_owner_key and eager_load_target_key.
    def eager_load(docs, additional_criteria = nil)
      owner_key  = eager_load_owner_key
      owner_type = eager_load_owner_type
      target_key = eager_load_target_key

      if is_a?(NoBrainer::Document::Association::BelongsTo::Metadata) && owner_type
        target_class = docs.first.__send__(owner_type)

        if docs.detect { |doc| doc.__send__(owner_type) != target_class }
          raise NoBrainer::Error::PolymorphicAssociationWithDifferentTypes,
                "The documents to be eager loaded doesn't have the same " \
                'type, which is not supported'
        end
      end

      criteria = target_class ? base_criteria(target_class) : base_criteria
      criteria = criteria.merge(additional_criteria) if additional_criteria

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

  def eager_load_association(docs, association_name, criteria=nil)
    docs = docs.compact
    return [] if docs.empty?

    meta = docs.first.class.association_metadata
    root_meta = docs.first.root_class.association_metadata
    association = meta[association_name.to_sym] || root_meta[association_name.to_sym] ||
      meta[association_name.to_s.singularize.to_sym] || root_meta[association_name.to_s.singularize.to_sym]

    raise "Unknown association #{association_name}" unless association
    association.eager_load(docs, criteria)
  end

  def eager_load(docs, what)
    case what
    when Hash then what.each do |k,v|
      if v.is_a?(NoBrainer::Criteria)
        v = v.dup
        nested_preloads, v.options[:eager_load] = v.options[:eager_load], []
        eager_load(eager_load_association(docs, k, v), nested_preloads)
      else
        eager_load(eager_load_association(docs, k), v)
      end
    end
    when Array then what.each { |v| eager_load(docs, v) }
    when nil then;
    else eager_load_association(docs, what) # String and Symbol
    end
    true
  end
end
