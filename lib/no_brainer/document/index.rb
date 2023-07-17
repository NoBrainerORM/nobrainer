# frozen_string_literal: true

module NoBrainer::Document::Index
  VALID_INDEX_OPTIONS = %i[external geo multi store_as defined].freeze
  extend ActiveSupport::Concern
  extend NoBrainer::Autoload

  autoload :Index, :Synchronizer, :MetaStore

  included do
    cattr_accessor :indexes, instance_accessor: false
    self.indexes = {}
  end

  module ClassMethods
    def index(name, *args)
      name = index_name_from(name, args)

      if name.in?(NoBrainer::Document::Attributes::RESERVED_FIELD_NAMES)
        raise "The index name `:#{name}' is reserved. Please use another one."
      end

      options = args.extract_options!
      options.assert_valid_keys(*VALID_INDEX_OPTIONS)

      raise "Too many arguments: #{args}" if args.size > 1

      kind, what = case args.first
                   when nil    then [:single,   name.to_sym]
                   when Array  then [:compound, args.first.map(&:to_sym)]
                   when Proc   then [:proc,     args.first]
                   else
                     raise 'Index argument must be a lambda or a list of fields'
                   end

      if has_field?(name) && kind != :single
        raise "The field `#{name}' is already declared. Please remove its " \
              'definition first.'
      end

      kind == :compound && what.size < 2 &&
        raise('Compound indexes only make sense with 2 or more fields')

      if options.delete(:defined)
        kind = :proc
        what = ->(doc) { doc.has_fields(name) }
      end

      store_as = options.delete(:store_as)
      store_as ||= fields[name][:store_as] if has_field?(name)
      store_as ||= name
      store_as = store_as.to_sym

      indexes[name] = NoBrainer::Document::Index::Index.new(
        root_class,
        name,
        store_as,
        kind,
        what,
        options[:external],
        options[:geo],
        options[:multi],
        nil
      )
    end

    def index_name_from(name, args)
      case name
      when String then name.to_sym
      when Symbol then name
      when Array
        args.unshift(name)
        name.map(&:to_s).join('_').to_sym
      else raise ArgumentError, 'Incorrect index specification'
      end
    end

    def remove_index(name)
      indexes.delete(name.to_sym)
    end

    def has_index?(name)
      !!indexes[name.to_sym]
    end

    def field(attr, options={})
      if has_index?(attr) && indexes[attr].kind != :single
        raise "The index `#{attr}' is already declared. Please remove its definition first."
      end

      super

      store_as = {:store_as => fields[attr][:store_as]}
      case options[:index]
      when nil    then
      when Hash   then index(attr, store_as.merge(options[:index]))
      when Symbol then index(attr, store_as.merge(options[:index] => true))
      when true   then index(attr, store_as)
      when false  then remove_index(attr)
      end
    end

    def remove_field(attr, options={})
      remove_index(attr) if fields[attr][:index]
      super
    end

    def lookup_index_alias(attr)
      indexes[attr.to_sym].try(:aliased_name) || attr
    end
  end
end
