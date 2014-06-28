module NoBrainer::Document::Attributes
  VALID_FIELD_OPTIONS = [:index, :default, :type,
                         :cast_user_to_model, :cast_db_to_model, :cast_model_to_db,
                         :validates, :required, :unique, :readonly, :primary_key]
  RESERVED_FIELD_NAMES = [:index, :default, :and, :or, :selector, :associations, :pk_value] \
                          + NoBrainer::DecoratedSymbol::MODIFIERS.keys
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

  def readable_attributes
    @_attributes.keys & self.class.fields.keys.map(&:to_s)
  end

  def attributes
    Hash[readable_attributes.map { |k| [k, read_attribute(k)] }].with_indifferent_access.freeze
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

  def assign_attributes(attrs, options={})
    @_attributes.clear if options[:pristine]
    if options[:from_db]
      @_attributes.merge!(attrs)
      clear_dirtiness
    else
      clear_dirtiness if options[:pristine]
      attrs.each { |k,v| self.write_attribute(k,v) }
    end
    assign_defaults if options[:pristine]
    self
  end

  def inspectable_attributes
    # TODO test that thing
    Hash[@_attributes.sort_by { |k,v| self.class.fields.keys.index(k.to_sym) || 2**10 }]
  end

  def to_s
    "#<#{self.class} #{self.class.pk_name}: #{self.pk_value.inspect}>"
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

    def _field(attr, options={})
      # Using a layer so the user can use super when overriding these methods
      attr = attr.to_s
      inject_in_layer :attributes do
        define_method("#{attr}=") { |value| @_attributes[attr] = value }
        define_method("#{attr}")  { @_attributes[attr] }
      end
    end

    def field(attr, options={})
      attr = attr.to_sym

      options.assert_valid_keys(*VALID_FIELD_OPTIONS)
      if attr.in?(RESERVED_FIELD_NAMES)
        raise "Cannot use a reserved field attr: #{attr}"
      end

      ([self] + descendants).each do |klass|
        klass.fields[attr] ||= {}
        klass.fields[attr].deep_merge!(options)
      end

      _field(attr, self.fields[attr])
    end

    def _remove_field(attr, options={})
      inject_in_layer :attributes do
        remove_method("#{attr}=")
        remove_method("#{attr}")
      end
    end

    def remove_field(attr, options={})
      attr = attr.to_sym

      _remove_field(attr, options)

      ([self] + descendants).each do |klass|
        klass.fields.delete(attr)
      end
    end

    def has_field?(attr)
      !!fields[attr.to_sym]
    end
  end
end
