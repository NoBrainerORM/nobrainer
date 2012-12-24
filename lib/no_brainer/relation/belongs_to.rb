class NoBrainer::Relation::BelongsTo < Struct.new(:klass, :parent, :options)
  def hook
    # TODO test options
    foreign_key = options[:foreign_key] || :"#{parent}_id"
    parent_klass = options[:class] || parent.to_s.camelize

    klass.field foreign_key

    klass.inject_in_layer :relations, <<-RUBY, __FILE__, __LINE__ + 1
      def #{foreign_key}=(value)
        super
        @relations_cache[:#{parent}] = nil
      end

      def #{parent}=(value)
        value.save! if value && !value.persisted?
        self.#{foreign_key} = value.try(:id)
        @relations_cache[:#{parent}] = value
      end

      def #{parent}
        if #{foreign_key}
          @relations_cache[:#{parent}] ||= #{parent_klass}.find(#{foreign_key})
        end
      end
    RUBY
  end
end
