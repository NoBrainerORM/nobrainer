module NoBrainer::Document::Relation
  extend ActiveSupport::Concern

  included do
    class << self; attr_accessor :relations; end
    self.relations = {}
  end

  def assign_attributes(*args)
    @relations_cache = {}
    super
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.relations = self.relations.dup
    end

    [:belongs_to, :has_many].each do |relation|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{relation}(target, options={})
          target = target.to_sym
          r = NoBrainer::Relation::#{relation.to_s.camelize}.new(self, target, options)
          r.hook

          ([self] + descendants).each do |klass|
            klass.relations[target] = r
          end
          r
        end
      RUBY
    end
  end
end
