module NoBrainer::Document::LazyFetch
  extend ActiveSupport::Concern

  included do
    singleton_class.send(:attr_accessor, :fields_to_lazy_fetch)
    self.fields_to_lazy_fetch = Set.new
  end

  def assign_attributes(attrs, options={})
    if options[:lazy_fetch].present?
      lazy_fetch = options[:lazy_fetch]
      lazy_fetch = lazy_fetch.keys if lazy_fetch.is_a?(Hash)
      @lazy_fetch = Set.new(lazy_fetch.map(&:to_s))
    end
    super
  end

  def reload(options={})
    lazy_fetch = self.class.fields_to_lazy_fetch.to_a
    return super unless lazy_fetch.present?
    return super if options[:pluck]
    super(options.deep_merge(:without => lazy_fetch, :lazy_fetch => lazy_fetch))
  end

  module ClassMethods
    def inherited(subclass)
      subclass.fields_to_lazy_fetch = self.fields_to_lazy_fetch.dup
      super
    end

    def _field(attr, options={})
      super
      attr = attr.to_s
      model = self
      inject_in_layer :lazy_fetch do
        if options[:lazy_fetch]
          model.for_each_subclass { |_model| _model.fields_to_lazy_fetch << attr }
        else
          model.for_each_subclass { |_model|  _model.fields_to_lazy_fetch.delete(attr) }
        end

        # Lazy loading can also specified through criteria.
        define_method("#{attr}") do
          return super() unless @lazy_fetch

          begin
            super()
          rescue NoBrainer::Error::MissingAttribute => e
            raise e unless attr.in?(@lazy_fetch)
            reload(:pluck => attr, :keep_ivars => true)
            @lazy_fetch.delete(attr)
            retry
          end
        end
      end
    end

    def _remove_field(attr, options={})
      super
      for_each_subclass { |model| model.fields_to_lazy_fetch.delete(attr) }
      inject_in_layer :lazy_fetch do
        remove_method("#{attr}") if method_defined?("#{attr}")
      end
    end

    def all
      criteria = super
      criteria = criteria.lazy_fetch(*self.fields_to_lazy_fetch) if self.fields_to_lazy_fetch.present?
      criteria
    end
  end
end
