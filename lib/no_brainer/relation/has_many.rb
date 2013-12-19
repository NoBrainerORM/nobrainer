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
    criteria.merge(children_klass.where(foreign_key => parent_instance.id))
  end

  def destroy_callback(parent_instance, how)
    case how
    when nil      then
    when :destroy then children_criteria(parent_instance).destroy_all
    when :delete  then children_criteria(parent_instance).delete_all
    when :nullify then children_criteria(parent_instance).update_all(foreign_key => nil)
    when :restrict
      unless children_criteria(parent_instance).count.zero?
        raise NoBrainer::Error::ChildrenExist
      end
    else raise "Unrecognized dependent option"
    end
    true
  end

  def hook
    # TODO yell when some options are not recognized

    if how = options[:dependent]
      relation = self
      parent_klass.before_destroy { relation.destroy_callback(self, how) }
    end

    parent_klass.inject_in_layer :relations, <<-RUBY, __FILE__, __LINE__ + 1
      def #{children_name}=(new_children)
        # FIXME it doesn't feel right to do a destroy on each children.
        # Perhaps we should do some sort of diff with the new children.
        # Perhaps we should not provide this method since its semantics are funny.
        self.class.relations[:#{children_name}].destroy_callback(self, :destroy)
        new_children.each { |child| #{children_name} << child }
      end

      def #{children_name}
        self.class.relations[:#{children_name}].children_criteria(self)
      end
    RUBY
  end
end
