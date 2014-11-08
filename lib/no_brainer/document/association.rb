module NoBrainer::Document::Association
  extend NoBrainer::Autoload
  autoload :Core, :BelongsTo, :HasMany, :HasManyThrough, :HasOne, :HasOneThrough, :EagerLoader
  METHODS = [:belongs_to, :has_many, :has_one]

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
      subclass.association_metadata = self.association_metadata.dup
      super
    end

    METHODS.each do |association|
      define_method(association) do |target, options={}|
        target = target.to_sym

        if r = self.association_metadata[target]
          raise "Cannot change the :through option" unless r.options[:through] == options[:through]
          r.options.merge!(options)
        else
          model_name = (options[:through] ? "#{association}_through" : association.to_s).camelize
          metadata_model = NoBrainer::Document::Association.const_get(model_name).const_get(:Metadata)
          r = metadata_model.new(self, target, options)
          ([self] + descendants).each do |model|
            model.association_metadata[target] = r
          end
        end
        r.hook
        r
      end
    end
  end
end
