class NoBrainer::Relation::HasMany::Selection < NoBrainer::Selection
  attr_accessor :parent_instance, :relation
  delegate :foreign_key, :children_klass, :to => :relation

  def initialize(parent_instance, relation)
    self.relation = relation
    self.parent_instance = parent_instance
    super children_klass.where(foreign_key => parent_instance.id)
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
