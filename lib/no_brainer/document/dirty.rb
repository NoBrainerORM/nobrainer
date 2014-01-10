module NoBrainer::Document::Dirty
  extend ActiveSupport::Concern
  # We need to save the changes as seen through read_attribute because
  # the user sees attributes through the read_attribute getters.
  # But we want to detect changes based on @_attributes to track
  # things like undefined -> nil. Going through the getters will
  # not give us that.

  def assign_attributes(attrs, options={})
    clear_dirtiness if options[:pristine]
    super
  end

  def _create(*args)
    super.tap { clear_dirtiness }
  end

  def _update(*args)
    super.tap { clear_dirtiness }
  end

  def clear_dirtiness
    @_old_attributes = {}.with_indifferent_access
    @_old_attributes_keys = @_attributes.keys # to track undefined -> nil changes
  end

  def changed?
    changes.present?
  end

  def changed
    changes.keys
  end

  def changes
    result = {}.with_indifferent_access
    @_old_attributes.each do |attr, old_value|
      current_value = read_attribute(attr)
      if current_value != old_value || !@_old_attributes_keys.include?(attr)
        result[attr] = [old_value, current_value]
      end
    end
    result
  end

  def attribute_may_change(attr, current_value)
    unless @_old_attributes.has_key?(attr)
      @_old_attributes[attr] = current_value.deep_dup
    end
  end

  module ClassMethods
    def field(name, options={})
      super
      name = name.to_s

      inject_in_layer :dirty_tracking do
        define_method("#{name}_change") do
          if @_old_attributes.has_key?(name)
            result = [@_old_attributes[name], read_attribute(name)]
            result if result.first != result.last || !@_old_attributes_keys.include?(name)
          end
        end

        define_method("#{name}_changed?") do
          !!__send__("#{name}_change")
        end

        define_method("#{name}_was") do
          @_old_attributes.has_key?(name) ? @_old_attributes[name] : read_attribute(name)
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
  end
end
