class NoBrainer::Relation::BelongsTo < Struct.new(:children_klass, :parent_name, :options)
  def foreign_key
    @foreign_key ||= options[:foreign_key] || :"#{parent_name}_id"
  end

  def parent_klass_lazy
    @parent_klass_lazy ||= options[:class] || parent_name.to_s.camelize
  end

  def hook
    children_klass.field foreign_key

    children_klass.inject_in_layer :relations, <<-RUBY, __FILE__, __LINE__ + 1
      def #{foreign_key}=(value)
        super
        @relations_cache[:#{parent_name}] = nil
      end

      def #{parent_name}=(new_parent)
        # TODO raise when new_parent doesn't have the proper type
        new_parent.save! if new_parent && !new_parent.persisted?
        self.#{foreign_key} = new_parent.try(:id)
        @relations_cache[:#{parent_name}] = new_parent
      end

      def #{parent_name}
        if #{foreign_key}
          @relations_cache[:#{parent_name}] ||= #{parent_klass_lazy}.find(#{foreign_key})
        end
      end
    RUBY
  end
end
