module NoBrainer::Base::Relation
  extend ActiveSupport::Concern

  def clear_internal_cache
    super
    @relations_cache = {}
  end

  module ClassMethods
    [:belongs_to, :has_many].each do |relation|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{relation}(target, options={})
          NoBrainer::Relation::#{relation.to_s.camelize}.new(self, target, options).hook
        end
      RUBY
    end
  end
end
