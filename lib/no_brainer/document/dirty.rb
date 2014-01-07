module NoBrainer::Document::Dirty
  extend ActiveSupport::Concern

  # We are not using ActiveModel::Dirty because it's using
  # ActiveModel::AttributeMethods which gives pretty violent method_missing()
  # capabilities, such as giving a getter/setter method for any keys within the
  # attributes keys. We don't want that.

  included do
    attr_accessor :previous_changes
    after_save { clear_dirtiness }
  end

  def changed_attributes
    @changed_attributes ||= {}
  end

  def _assign_attributes(attrs, options={})
    super
    clear_dirtiness if options[:pristine]
  end

  def clear_dirtiness
    self.previous_changes = changes
    self.changed_attributes.clear
  end

  def changed?
    changed_attributes.present?
  end

  def changed
    changed_attributes.keys
  end

  def changes
    Hash[changed_attributes.map { |k,v| [k, [v, read_attribute(k)]] }]
  end

  def attribute_will_change!(attr, new_value)
    return if changed_attributes.include?(attr)

    # ActiveModel ignores TypeError and NoMethodError exception as if nothng
    # happened. Why is that?
    value = read_attribute(attr)
    value = value.clone if value.duplicable?

    return if value == new_value

    changed_attributes[attr] = value
  end

  module ClassMethods
    def field(name, options={})
      super

      inject_in_layer :dirty_tracking, <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}_changed?
          changed_attributes.include?(:#{name})
        end

        def #{name}_change
          [changed_attributes[:#{name}], #{name}] if #{name}_changed?
        end

        def #{name}_was
          #{name}_changed? ? changed_attributes[:#{name}] : #{name}
        end

        def #{name}=(value)
          attribute_will_change!(:#{name}, value)
          super
        end
      RUBY
    end

    def remove_field(name)
      super

      inject_in_layer :dirty_tracking, <<-RUBY, __FILE__, __LINE__ + 1
        undef #{name}_changed?
        undef #{name}_change
        undef #{name}_was
        undef #{name}=
      RUBY
    end
  end
end
