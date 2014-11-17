module NoBrainer::Document::Aliases
  extend ActiveSupport::Concern

  # Index aliases are built-in index.rb

  included do
    # We ignore polymorphism for aliases.
    cattr_accessor :alias_map, :alias_reverse_map, :instance_accessor => false
    self.alias_map = {}
    self.alias_reverse_map = {}
  end

  module ClassMethods
    def _field(attr, options={})
      if options[:store_as]
        self.alias_map[attr.to_s] = options[:store_as].to_s
        self.alias_reverse_map[options[:store_as].to_s] = attr.to_s
      end
      super
    end

    def field(attr, options={})
      if options[:as]
        STDERR.puts "[NoBrainer] `:as' is deprecated and will be removed. Please use `:store_as' instead (from the #{self} model)"
        options[:store_as] = options.delete(:as)
      end
      super
    end

    def _remove_field(attr, options={})
      super

      self.alias_map.delete(attr.to_s)
      self.alias_reverse_map.delete(attr.to_s)
    end

    def reverse_lookup_field_alias(attr)
      alias_reverse_map[attr.to_s] || attr
    end

    def lookup_field_alias(attr)
      alias_map[attr.to_s] || attr
    end

    def with_fields_reverse_aliased(attrs)
      case attrs
      when Array then attrs.map { |k| reverse_lookup_field_alias(k) }
      when Hash  then Hash[attrs.map { |k,v| [reverse_lookup_field_alias(k), v] }]
      end
    end

    def with_fields_aliased(attrs)
      case attrs
      when Array then attrs.map { |k| lookup_field_alias(k) }
      when Hash  then Hash[attrs.map { |k,v| [lookup_field_alias(k), v] }]
      end
    end

    def persistable_key(k, options={})
      lookup_field_alias(super)
    end
  end
end
