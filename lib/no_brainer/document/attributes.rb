module NoBrainer::Document::Attributes
  VALID_FIELD_OPTIONS = [:index, :default, :type, :readonly, :primary_key, :lazy_fetch, :store_as,
                         :validates, :required, :unique, :uniq, :format, :in, :length]
  RESERVED_FIELD_NAMES = [:index, :default, :and, :or, :selector, :associations, :pk_value] \
                          + NoBrainer::Criteria::Where::OPERATORS
  extend ActiveSupport::Concern

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
      next unless field_options.has_key?(:default) &&
                  !@_attributes.has_key?(name)

      if opt = options[:missing_attributes]
        if (opt[:pluck] && !opt[:pluck][name]) ||
           (opt[:without] && opt[:without][name])
          next
        end
      end

      default_value = field_options[:default]
      default_value = default_value.call if default_value.is_a?(Proc)
      self.write_attribute(name, default_value)
    end
  end

  def assign_attributes(attrs, options={})
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
      attrs.each { |k,v| self.write_attribute(k,v) }
    end
    assign_defaults(options) if options[:pristine]
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
      model_from_attrs(attrs).new(attrs, options) if attrs
    end

    def inherited(subclass)
      subclass.fields = self.fields.dup
      super
    end

    def _field(attr, options={})
      # Using a layer so the user can use super when overriding these methods
      attr = attr.to_s
      inject_in_layer :attributes do
        define_method("#{attr}=") { |value| _write_attribute(attr, value) }
        define_method("#{attr}") { _read_attribute(attr) }
      end
    end

    def field(attr, options={})
      attr = attr.to_sym

      options.assert_valid_keys(*VALID_FIELD_OPTIONS)
      if attr.in?(RESERVED_FIELD_NAMES)
        raise "Cannot use a reserved field attr: #{attr}"
      end

      ([self] + descendants).each do |model|
        model.fields[attr] ||= {}
        model.fields[attr].deep_merge!(options)
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

      ([self] + descendants).each do |model|
        model.fields.delete(attr)
      end
    end

    def has_field?(attr)
      !!fields[attr.to_sym]
    end
  end
end
