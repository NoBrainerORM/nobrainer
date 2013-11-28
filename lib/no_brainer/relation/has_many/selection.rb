class NoBrainer::Relation::HasMany::Selection < NoBrainer::Selection
  attr_accessor :parent_instance, :relation, :conditions
  delegate :children_foreign_key, :through_klass, :foreign_key, :children_klass, :to => :relation

  def initialize(parent_instance, relation, conditions = {})
    self.relation = relation
    self.parent_instance = parent_instance
    self.conditions = conditions

    if through_klass
      query = through_klass.where(conditions.merge({foreign_key => parent_instance.id})).eq_join(children_foreign_key, children_klass.table).map { |r| r[:right]}
      query.context =  {:klass => children_klass}
      super query
    else
      super children_klass.where(foreign_key => parent_instance.id)
    end
  end

  def <<(child)
    # TODO raise when child doesn't have the proper type
    if through_klass
      through_klass.create(conditions.merge({foreign_key => parent_instance.id, children_foreign_key => child.id}))
    else
      child.update_attributes(foreign_key => parent_instance.id)
    end
  end

  def build(attrs={})
    if through_klass
      children_klass.new(attrs)
    else
      children_klass.new(attrs.merge(foreign_key => parent_instance.id))
    end
  end

  def create(*args)
    if through_klass
      build(*args).tap do |doc|
        doc.save
        through_klass.create(conditions.merge({foreign_key => parent_instance.id, children_foreign_key => doc.id}))
      end
    else
      build(*args).tap { |doc| doc.save }
    end
  end

  def create!(*args)
    if through_klass
      build(*args).tap do |doc|
        doc.save!
        through_klass.create!(conditions.merge({foreign_key => parent_instance.id, children_foreign_key => doc.id}))
      end 
    else
      build(*args).tap { |doc| doc.save! }
    end
  end
end
