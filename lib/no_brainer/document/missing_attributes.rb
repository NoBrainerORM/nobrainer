module NoBrainer::Document::MissingAttributes
  extend ActiveSupport::Concern

  def write_attribute(attr, value)
    super.tap { clear_missing_field(attr) }
  end

  def assign_attributes(attrs, options={})
    # there is one and only one key :pluck or :without to missing_attributes
    if options[:missing_attributes]
      # TODO XXX this whole thing is gross.
      # if @missing_attributes is already there, it's because we are doing a
      # incremental reload. clear_missing_field will do the work of recognizing
      # which fields are here or not.
      @missing_attributes ||= options[:missing_attributes]

      assert_access_field(self.class.pk_name, "The primary key is not accessible. Use .raw or")
      assert_access_field(:_type, "The subclass type is not accessible. Use .raw or") if self.class.is_polymorphic
    end

    attrs.keys.each { |attr| clear_missing_field(attr) } if @missing_attributes && options[:from_db]

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

  def _read_attribute(name)
    assert_access_field(name)
    super
  end

  def _write_attribute(name, value)
    super.tap { clear_missing_field(name) }
  end
end
