class NoBrainer::Relation::HasMany::Criteria < NoBrainer::Criteria
  delegate :foreign_key, :children_klass, :to => :relation

  def parent_instance
    options[:parent_instance]
  end

  def relation
    options[:relation]
  end

  def <<(child)
    # TODO raise when child doesn't have the proper type
    child.update_attributes(foreign_key => parent_instance.id)
  end

  def build(attrs={})
    children_klass.new(attrs.merge(foreign_key => parent_instance.id))
  end

  def create(*args)
    build(*args).tap { |doc| doc.save }
  end

  def create!(*args)
    build(*args).tap { |doc| doc.save! }
  end
end
