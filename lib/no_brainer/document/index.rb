module NoBrainer::Document::Index
  VALID_INDEX_OPTIONS = [:external, :geo, :multi, :as]
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload :Index, :Synchronizer, :MetaStore

  included do
    cattr_accessor :indexes, :instance_accessor => false
    self.indexes = {}
  end

  module ClassMethods
    def index(name, *args)
      name = name.to_sym
      options = args.extract_options!
      options.assert_valid_keys(*VALID_INDEX_OPTIONS)

      raise "Too many arguments: #{args}" if args.size > 1

      kind, what = case args.first
        when nil    then [:single,   name.to_sym]
        when Array  then [:compound, args.first.map(&:to_sym)]
        when Proc   then [:proc,     args.first]
        else raise "Index argument must be a lambda or a list of fields"
      end

      if name.in?(NoBrainer::Document::Attributes::RESERVED_FIELD_NAMES)
        raise "Cannot use a reserved field name: #{name}"
      end

      if has_field?(name) && kind != :single
        raise "Cannot reuse field name #{name}"
      end

      as = options.delete(:as)
      as ||= fields[name][:as] if has_field?(name)
      as ||= name
      as = as.to_sym

      indexes[name] = NoBrainer::Document::Index::Index.new(self.root_class, name, as,
        kind, what, options[:external], options[:geo], options[:multi], nil)
    end

    def remove_index(name)
      indexes.delete(name.to_sym)
    end

    def has_index?(name)
      !!indexes[name.to_sym]
    end

    def _field(attr, options={})
      if has_index?(attr) && indexes[attr].kind != :single
        raise "Cannot reuse index attr #{attr}"
      end

      super

      as = {:as => options[:as]}
      case options[:index]
      when nil    then
      when Hash   then index(attr, as.merge(options[:index]))
      when Symbol then index(attr, as.merge(options[:index] => true))
      when true   then index(attr, as)
      when false  then remove_index(attr)
      end
    end

    def _remove_field(attr, options={})
      remove_index(attr) if fields[attr][:index]
      super
    end

    def lookup_index_alias(attr)
      indexes[attr.to_sym].try(:aliased_name) || attr
    end
  end
end
