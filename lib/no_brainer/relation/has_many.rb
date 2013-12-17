class NoBrainer::Relation::HasMany < Struct.new(:parent_klass, :children_name, :options)
  extend ActiveSupport::Autoload
  autoload :Criteria

  def foreign_key
    # TODO test :foreign_key
    @foreign_key ||= options[:foreign_key] || :"#{parent_klass.name.underscore}_id"
  end

  def children_klass
    # TODO test :class_name
    @children_klass ||= (options[:class_name] || children_name.to_s.singularize.camelize).constantize
  end

  def children_criteria(parent_instance)
    options = {:parent_instance => parent_instance, :relation => self}
    criteria = ::NoBrainer::Relation::HasMany::Criteria.new(options)
    criteria.merge(children_klass.where(self.foreign_key => parent_instance.id))
  end

  def hook
    # TODO yell when some options are not recognized
    parent_klass.inject_in_layer :relations, <<-RUBY, __FILE__, __LINE__ + 1
      def #{children_name}=(new_children)
        #{children_name}.destroy
        new_children.each { |child| #{children_name} << child }
      end

      def #{children_name}
        # TODO Cache array
        self.class.relations[:#{children_name}].children_criteria(self)
      end
    RUBY
  end
end
