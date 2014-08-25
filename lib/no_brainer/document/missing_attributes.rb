module NoBrainer::Document::MissingAttributes
  extend ActiveSupport::Concern

  def write_attribute(attr, value)
    super.tap { clear_missing_field(attr) }
  end

  def assign_attributes(attrs, options={})
    if options[:missing_attributes]
      @missing_attributes = options[:missing_attributes]
      assert_access_field(self.class.pk_name, "The primary key is not accessible. Use .raw or")
      assert_access_field(:_type, "The subclass type is not accessible. Use .raw or") if self.class.is_polymorphic
    end

    super
  end

  def missing_field?(name)
    return false unless @missing_attributes
    name = name.to_s
    return false if @cleared_missing_fields.try(:[], name)
    if @missing_attributes[:pluck]
      !@missing_attributes[:pluck][name]
    else
      !!@missing_attributes[:without][name]
    end
  end

  def clear_missing_field(name)
    return unless @missing_attributes
    @cleared_missing_fields ||= {}
    @cleared_missing_fields[name.to_s] = true
  end

  def assert_access_field(name, msg=nil)
    if missing_field?(name)
      method = @missing_attributes.keys.first
      msg ||= "The attribute `#{name}' is not accessible,"
      msg += " add `:#{name}' to pluck()" if method == :pluck
      msg += " remove `:#{name}' from without()" if method == :without
      raise NoBrainer::Error::MissingAttribute.new(msg)
    end
  end


  module ClassMethods
    def _field(attr, options={})
      super

      inject_in_layer :missing_attributes do
        define_method("#{attr}") do
          assert_access_field(attr)
          super()
        end

        define_method("#{attr}=") do |value|
          super(value).tap { clear_missing_field(attr) }
        end
      end
    end

    def _remove_field(attr, options={})
      super
      inject_in_layer :missing_attributes do
        remove_method("#{attr}=")
        remove_method("#{attr}")
      end
    end
  end
end
