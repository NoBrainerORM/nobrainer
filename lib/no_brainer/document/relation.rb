module NoBrainer::Document::Relation
  extend ActiveSupport::Concern

  def clear_internal_cache
    super
    @relations_cache = {}
  end

  module ClassMethods
    def relations
      @relations
    end

    [:belongs_to, :has_many].each do |relation|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{relation}(target, options={})
          target = target.to_sym
          r = NoBrainer::Relation::#{relation.to_s.camelize}.new(self, target, options)
          r.hook

          # FIXME Inheritence will not work well.
          @relations ||= {}
          @relations[target] = r
        end
      RUBY
    end
  end
end
