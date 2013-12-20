module NoBrainer::Document::Relation
  extend NoBrainer::Autoload
  autoload :Core, :BelongsTo, :HasMany

  extend ActiveSupport::Concern

  included do
    class << self; attr_accessor :relation_metadata; end
    self.relation_metadata = {}
  end

  def relation(metadata)
    @relations ||= {}
    @relations[metadata] ||= metadata.new(self)
  end

  def assign_attributes(*args)
    @relations = nil
    super
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.relation_metadata = self.relation_metadata.dup
    end

    [:belongs_to, :has_many].each do |relation|
      define_method(relation) do |target, options={}|
        target = target.to_sym

        if r = self.relation_metadata[target]
          r.options.merge!(options)
        else
          metadata_klass = NoBrainer::Document::Relation.const_get(relation.to_s.camelize).const_get(:Metadata)
          r = metadata_klass.new(self, target, options)
          ([self] + descendants).each do |klass|
            klass.relation_metadata[target] = r
          end
        end
        r.hook
        r
      end
    end
  end
end
