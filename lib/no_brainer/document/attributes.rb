module NoBrainer::Document::Attributes
  VALID_FIELD_OPTIONS = [:index, :default, :type, :readonly, :primary_key,
                         :lazy_fetch, :store_as, :validates, :required, :unique,
                         :uniq, :format, :in, :length, :min_length, :max_length,
                         :prefix, :suffix, :virtual]
  RESERVED_FIELD_NAMES = [:index, :default, :and, :or, :selector, :associations, :pk_value] +
                          NoBrainer::SymbolDecoration::OPERATORS

  extend ActiveSupport::Concern
  include ActiveModel::ForbiddenAttributesProtection

  included do
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

  def raw_attributes
    @_attributes
  end

  def _read_attribute(name)
    @_attributes[name]
  end

  def _write_attribute(name, value)
    @_attributes[name] = value
  end

  def read_attribute(name)
    __send__("#{name}")
  end
  def [](*args); read_attribute(*args); end

  def write_attribute(name, value)
    __send__("#{name}=", value)
  end
  def []=(*args); write_attribute(*args); end

  def assign_defaults(options)
    self.class.fields.each do |name, field_options|
      # :default => nil will not set the value to nil, but :default => ->{ nil } will.
      # This is useful to unset a default value.

      next if field_options[:default].nil? || @_attributes.key?(name)

      if opt = options[:missing_attributes]
        if (opt[:pluck] && !opt[:pluck][name]) ||
           (opt[:without] && opt[:without][name])
          next
        end
      end

      default_value = field_options[:default]
      default_value = instance_exec(&default_value) if default_value.is_a?(Proc)
      self.write_attribute(name, default_value)
    end
  end

  def assign_attributes(attrs, options={})
    attrs = attrs.to_h if !attrs.is_a?(Hash) && attrs.respond_to?(:to_h)
    raise ArgumentError, "To assign attributes, please pass a hash instead of `#{attrs.class}'" unless attrs.is_a?(Hash)

    if options[:pristine]
      if options[:keep_ivars] && options[:missing_attributes].try(:[], :pluck)
        options[:missing_attributes][:pluck].keys.each { |k| @_attributes.delete(k) }
      else
        @_attributes.clear
      end
    end

    if options[:from_db]
      attrs = self.class.with_fields_reverse_aliased(attrs)
      @_attributes.merge!(attrs)
      clear_dirtiness(options)
    else
      clear_dirtiness(options) if options[:pristine]
      attrs = sanitize_for_mass_assignment(attrs)
      attrs.each { |k,v| self.write_attribute(k,v) }
    end
    assign_defaults(options) if options[:pristine]
    self
  end

  def inspectable_attributes
    # TODO test that thing
    Hash[@_attributes.sort_by { |k,v| self.class.fields.keys.index(k.to_sym) || 2**10 }].with_indifferent_access.freeze
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
      model_from_attrs(attrs).new(attrs, options) if attrs
    end

    def inherited(subclass)
      subclass.fields = self.fields.dup
      super
    end

    def field(attr, options={})
      options.assert_valid_keys(*VALID_FIELD_OPTIONS)
      unless attr.is_a?(Symbol)
        raise "The field `#{attr}' must be declared with a Symbol" # we're just being lazy here...
      end
      if attr.in?(RESERVED_FIELD_NAMES)
        raise "The field name `:#{attr}' is reserved. Please use another one."
      end

      subclass_tree.each do |subclass|
        subclass.fields[attr] ||= {}
        subclass.fields[attr].deep_merge!(options)
      end

      attr = attr.to_s
      inject_in_layer :attributes do
        define_method("#{attr}=") { |value| _write_attribute(attr, value) }
        define_method("#{attr}") { _read_attribute(attr) }
      end
    end

    def remove_field(attr, options={})
      inject_in_layer :attributes do
        remove_method("#{attr}=")
        remove_method("#{attr}")
      end

      subclass_tree.each do |subclass|
        subclass.fields.delete(attr)
      end
    end

    def has_field?(attr)
      !!fields[attr.to_sym]
    end

    def ensure_valid_key!(key)
      return if has_field?(key) || has_index?(key)
      raise NoBrainer::Error::UnknownAttribute, "`#{key}' is not a valid attribute of #{self}"
    end
  end
end
