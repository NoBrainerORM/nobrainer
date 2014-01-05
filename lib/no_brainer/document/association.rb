module NoBrainer::Document::Association
  extend NoBrainer::Autoload
  autoload :Core, :BelongsTo, :HasMany, :HasManyThrough, :EagerLoader

  extend ActiveSupport::Concern

  included do
    singleton_class.send(:attr_accessor, :association_metadata)
    self.association_metadata = {}
  end

  def associations
    @associations ||= Hash.new { |h, metadata| h[metadata] = metadata.new(self) }
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
          raise "Cannot change the :through option" unless r.options[:through] == options[:through]
          r.options.merge!(options)
        else
          klass_name = (options[:through] ? "#{association}_through" : association.to_s).camelize
          metadata_klass = NoBrainer::Document::Association.const_get(klass_name).const_get(:Metadata)
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
