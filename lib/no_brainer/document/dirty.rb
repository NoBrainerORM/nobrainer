module NoBrainer::Document::Dirty
  extend ActiveSupport::Concern
  # We need to save the changes as seen through read_attribute because
  # the user sees attributes through the read_attribute getters.
  # But we want to detect changes based on @_attributes to track
  # things like undefined -> nil. Going through the getters will
  # not give us that.

  def _create(*args)
    super.tap { clear_dirtiness }
  end

  def _update(*args)
    super.tap { clear_dirtiness }
  end

  def clear_dirtiness(options={})
    if options[:keep_ivars] && options[:missing_attributes].try(:[], :pluck)
      attrs = options[:missing_attributes][:pluck].keys
      @_old_attributes = @_old_attributes.reject { |k,v| attrs.include?(k) } else @_old_attributes = {}.with_indifferent_access
    end

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

  def attribute_may_change(*args)
    attr = args.first
    current_value = begin
      case args.size
      when 1 then assert_access_field(attr); read_attribute(attr)
      when 2 then args.last
      else raise
      end
    rescue NoBrainer::Error::MissingAttribute => e
      e
    end

    unless @_old_attributes.has_key?(attr)
      @_old_attributes[attr] = current_value.deep_dup
    end
  end

  def _read_attribute(name)
    super.tap do |value|
      # This take care of string/arrays/hashes that could change without going
      # through the setter.
      attribute_may_change(name, value) if value.respond_to?(:size)
    end
  end

  def _write_attribute(name, value)
    attribute_may_change(name)
    super
  end

  module ClassMethods
    def _field(attr, options={})
      super
      attr = attr.to_s

      inject_in_layer :dirty_tracking do
        define_method("#{attr}_change") do
          if @_old_attributes.has_key?(attr)
            result = [@_old_attributes[attr], read_attribute(attr)]
            result if result.first != result.last || !@_old_attributes_keys.include?(attr)
          end
        end

        define_method("#{attr}_changed?") do
          !!__send__("#{attr}_change")
        end

        define_method("#{attr}_was") do
          @_old_attributes.has_key?(attr) ? @_old_attributes[attr] : read_attribute(attr)
        end
      end
    end

    def _remove_field(attr, options={})
      super
      inject_in_layer :dirty_tracking do
        remove_method("#{attr}_change")
        remove_method("#{attr}_changed?")
        remove_method("#{attr}_was")
      end
    end
  end
end
