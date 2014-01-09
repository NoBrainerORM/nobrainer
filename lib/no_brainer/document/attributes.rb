module NoBrainer::Document::Attributes
  VALID_FIELD_OPTIONS = [:index, :default, :type, :type_cast_method, :validates]
  RESERVED_FIELD_NAMES = [:index, :default, :and, :or, :selector, :associations] + NoBrainer::DecoratedSymbol::MODIFIERS.keys
  extend ActiveSupport::Concern

  included do
    # Not using class_attribute because we want to
    # use our custom logic
    singleton_class.send(:attr_accessor, :fields)
    self.fields = {}
  end

  def _initialize(attrs={}, options={})
    @_attributes = {}.with_indifferent_access
    assign_attributes(attrs, options.reverse_merge(:pristine => true))
  end

  def attributes
    Hash[@_attributes.keys.map { |k| [k, read_attribute(k)] }].with_indifferent_access.freeze
  end

  def read_attribute(name)
    __send__("#{name}")
  end
  def [](*args); read_attribute(*args); end

  def write_attribute(name, value)
    __send__("#{name}=", value)
  end
  def []=(*args); write_attribute(*args); end

  def assign_defaults
    self.class.fields.each do |name, field_options|
      if field_options.has_key?(:default) && !@_attributes.has_key?(name)
        default_value = field_options[:default]
        default_value = default_value.call if default_value.is_a?(Proc)
        self.write_attribute(name, default_value)
      end
    end
  end

  def _assign_attributes(attrs, options={})
    attrs.each { |k,v| self.write_attribute(k,v) }
  end

  def assign_attributes(attrs, options={})
    @_attributes.clear if options[:pristine]
    _assign_attributes(attrs, options)
    assign_defaults if options[:pristine]
    self
  end
  def attributes=(*args); assign_attributes(*args); end

  def inspectable_attributes
    # TODO test that thing
    Hash[@_attributes.sort_by { |k,v| self.class.fields.keys.index(k.to_sym) || 2**10 }]
  end

  def inspect
    "#<#{self.class} #{inspectable_attributes.map { |k,v| "#{k}: #{v.inspect}" }.join(', ')}>"
  end

  module ClassMethods
    def new_from_db(attrs, options={})
      options = options.reverse_merge(:pristine => true, :from_db => true)
      klass_from_attrs(attrs).new(attrs, options) if attrs
    end

    def inherited(subclass)
      super
      subclass.fields = self.fields.dup
    end

    def field(name, options={})
      name = name.to_sym

      options.assert_valid_keys(*VALID_FIELD_OPTIONS)
      if name.in?(RESERVED_FIELD_NAMES)
        raise "Cannot use a reserved field name: #{name}"
      end

      ([self] + descendants).each do |klass|
        klass.fields[name] ||= {}
        klass.fields[name].merge!(options)
      end

      # Using a layer so the user can use super when overriding these methods
      inject_in_layer :attributes, <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}=(value)
          @_attributes['#{name}'] = value
        end

        def #{name}
          @_attributes['#{name}']
        end
      RUBY
    end

    def has_field?(name)
      !!fields[name.to_sym]
    end
  end
end
