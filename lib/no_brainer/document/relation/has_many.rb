class NoBrainer::Document::Relation::HasMany
  class Metadata
    include NoBrainer::Document::Relation::Core::Metadata

    def foreign_key
      # TODO test :foreign_key
      @foreign_key ||= options[:foreign_key] || :"#{lhs_klass.name.underscore}_id"
    end

    def rhs_klass
      # TODO test :class_name
      @rhs_klass ||= (options[:class_name] || rhs_name.to_s.singularize.camelize).constantize
    end

    def hook
      # TODO yell when some options are not recognized
      metadata = self
      @foreign_key = nil
      @rhs_klass = nil

      if options[:dependent] && !@added_destroy_callback
        lhs_klass.before_destroy { relation(metadata).destroy_callback }
        @added_destroy_callback = true
      end

      delegate("#{rhs_name}", :read)
      delegate("#{rhs_name}=", :write)
    end
  end

  class Criteria < NoBrainer::Criteria
    delegate :<<, :build, :create, :create!, :to => :relation

    def relation
      options[:relation]
    end
  end

  include NoBrainer::Document::Relation::Core
  delegate :foreign_key, :rhs_klass, :to => :metadata

  def children_criteria
    @children_criteria ||= begin
      criteria = rhs_klass.where(foreign_key => instance.id)
      Criteria.new(:relation => self).merge(criteria)
    end
  end

  def destroy_callback(how=nil)
    criteria = children_criteria.unscoped
    case how || metadata.options[:dependent]
    when nil       then
    when :destroy  then criteria.destroy_all
    when :delete   then criteria.delete_all
    when :nullify  then criteria.update_all(foreign_key => nil)
    when :restrict then raise NoBrainer::Error::ChildrenExist unless criteria.count.zero?
    else raise "Unrecognized dependent option"
    end
    true
  end

  def read
    children_criteria
  end

  def write(new_children)
    destroy_callback(:destroy)
    new_children.each { |child| self << child }
  end

  def <<(child)
    # TODO raise when child doesn't have the proper type
    child.update_attributes(foreign_key => instance.id)
  end

  def build(attrs={})
    rhs_klass.new(attrs.merge(foreign_key => instance.id))
  end

  def create(*args)
    build(*args).tap { |doc| doc.save }
  end

  def create!(*args)
    build(*args).tap { |doc| doc.save! }
  end
end
