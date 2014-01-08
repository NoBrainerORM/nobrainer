module NoBrainer::Document::Dirty
  extend ActiveSupport::Concern

  # We are not using ActiveModel::Dirty because it's using
  # ActiveModel::AttributeMethods which gives pretty violent method_missing()
  # capabilities, such as giving a getter/setter method for any keys within the
  # attributes keys. We don't want that.
  # Also it doesn't work properly with array and hashes

  included { after_save { clear_dirtiness } }

  def old_attributes_values
    @old_attributes_values ||= {}.with_indifferent_access
  end

  def clear_dirtiness
    @old_attributes_values.try(:clear)
  end

  def attributes
    # If we leak all the attributes (rare), we perform a copy to ensure that we
    # don't have issues with modified hashes/array. Devs are crazy.
    super.tap { |attrs| @old_attributes_values = attrs.deep_dup.with_indifferent_access }
  end

  def _assign_attributes(attrs, options={})
    super
    clear_dirtiness if options[:from_db]
  end

  def changed?
    changes.present?
  end

  def changed
    changes.keys
  end

  def changes
    result = {}.with_indifferent_access
    old_attributes_values.each do |attr, old_value|
      current_value = read_attribute(attr)
      result[attr] = [old_value, current_value] if current_value != old_value
    end
    result
  end

  def attribute_may_change(attr, current_value)
    unless old_attributes_values.has_key?(attr)
      old_attributes_values[attr] = current_value.deep_dup
    end
  end

  module ClassMethods
    def field(name, options={})
      super

      inject_in_layer :dirty_tracking do
        define_method("#{name}_change") do
          if old_attributes_values.has_key?(name)
            result = [old_attributes_values[name], read_attribute(name)]
            result = nil if result.first == result.last
            result
          end
        end

        define_method("#{name}_changed?") do
          !!__send__("#{name}_change")
        end

        define_method("#{name}_was") do
          old_attributes_values.has_key?(name) ?
            old_attributes_values[name] : read_attribute(name)
        end

        define_method("#{name}") do
          super().tap do |value|
            # This take care of string/arrays/hashes that could change without going
            # through the setter.
            attribute_may_change(name, value) if value.respond_to?(:size)
          end
        end

        define_method("#{name}=") do |value|
          attribute_may_change(name, read_attribute(name))
          super(value)
        end
      end
    end

    def remove_field(name)
      super

      inject_in_layer :dirty_tracking, <<-RUBY, __FILE__, __LINE__ + 1
        undef #{name}_changed?
        undef #{name}_change
        undef #{name}_was
        undef #{name}
        undef #{name}=
      RUBY
    end
  end
end
