class NoBrainer::Relation::HasMany < Struct.new(:parent_klass, :children_name, :options)
  extend ActiveSupport::Autoload
  autoload :Selection

  def foreign_key
    @foreign_key ||= options[:foreign_key] || :"#{parent_klass.name.underscore}_id"
  end

  def children_klass
    @children_klass ||= (options[:class] || children_name.to_s.singularize.camelize).constantize
  end

  def hook
    # TODO yell when some options are not recognized
    parent_klass.inject_in_layer :relations, <<-RUBY, __FILE__, __LINE__ + 1
      def #{children_name}=(new_children)
        #{children_name}.destroy
        new_children.each { |child| #{children_name} << child }
      end

      def #{children_name}
        # TODO Cache array when we have one
        relation = self.class.relations[:#{children_name}]
        ::NoBrainer::Relation::HasMany::Selection.new(self, relation)
      end
    RUBY
  end
end
