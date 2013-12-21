class NoBrainer::Document::Relation::HasMany
  include NoBrainer::Document::Relation::Core

  class Metadata
    include NoBrainer::Document::Relation::Core::Metadata

    def foreign_key
      # TODO test :foreign_key
      @foreign_key ||= options[:foreign_key] || :"#{owner_klass.name.underscore}_id"
    end

    def target_klass
      # TODO test :class_name
      @target_klass ||= (options[:class_name] || target_name.to_s.singularize.camelize).constantize
    end

    def hook
      super
      @foreign_key = nil
      @target_klass = nil

      options.assert_valid_keys(:foreign_key, :class_name, :dependent)

      if options[:dependent] && !@added_destroy_callback
        metadata = self
        owner_klass.before_destroy { relation(metadata).destroy_callback }
        @added_destroy_callback = true
      end
    end
  end

  class Criteria < NoBrainer::Criteria
    delegate :build, :create, :create!, :to => :relation

    def relation
      options[:relation]
    end

    def <<(child)
      relation << child
      self
    end
  end

  def read
    children_criteria
  end

  def write(new_children)
    destroy_callback(:destroy)
    new_children.each { |child| self << child }
  end

  def children_criteria
    @children_criteria ||= begin
      criteria = target_klass.where(foreign_key => instance.id)
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

  def <<(child)
    assert_target_type(child)
    child.update_attributes(foreign_key => instance.id)
    self
  end

  def build(attrs={})
    target_klass.new(attrs.merge(foreign_key => instance.id))
  end

  def create(*args)
    build(*args).tap { |doc| doc.save }
  end

  def create!(*args)
    build(*args).tap { |doc| doc.save! }
  end
end
