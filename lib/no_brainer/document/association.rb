module NoBrainer::Document::Association
  extend NoBrainer::Autoload
  autoload :Core, :BelongsTo, :HasMany

  extend ActiveSupport::Concern

  included do
    class << self; attr_accessor :association_metadata; end
    self.association_metadata = {}
  end

  def association(metadata)
    @associations ||= {}
    @associations[metadata] ||= metadata.new(self)
  end

  module ClassMethods
    def inherited(subclass)
      super
      subclass.association_metadata = self.association_metadata.dup
    end

    [:belongs_to, :has_many].each do |association|
      define_method(association) do |target, options={}|
        target = target.to_sym

        if r = self.association_metadata[target]
          r.options.merge!(options)
        else
          metadata_klass = NoBrainer::Document::Association.const_get(association.to_s.camelize).const_get(:Metadata)
          r = metadata_klass.new(self, target, options)
          ([self] + descendants).each do |klass|
            klass.association_metadata[target] = r
          end
        end
        r.hook
        r
      end
    end
  end
end
