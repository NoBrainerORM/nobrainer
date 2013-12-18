module NoBrainer::Document::Index
  extend ActiveSupport::Concern

  included do
    class_attribute :indexes
    self.indexes = {}
  end

  module ClassMethods
    def index(name, *args)
      options = args.extract_options!
      raise "Too many arguments: #{args}" if args.size > 1
      kind, what = case args.first
        when nil   then [:single,   name.to_sym]
        when Array then [:compound, args.first.map(&:to_sym)]
        when Proc  then [:proc,     args.first]
        else raise "Index argument must be a lambda or a list of fields"
      end
      indexes[name.to_sym] = {:kind => kind, :what => what, :options => options}
    end

    def remove_index(name)
      indexes.delete(name.to_sym)
    end

    def field(name, options={})
      super
      index(name) if options[:index]
    end

    def remove_field(name)
      remove_index(name) if fields[name.to_sym][:index]
      super
    end

    def perform_create_index(index_name, options={})
      index_name = index_name.to_sym
      index_args = self.indexes[index_name]

      index_proc = case index_args[:kind]
        when :single   then nil
        when :compound then ->(doc) { index_args[:what].map { |field| doc[field] } }
        when :proc     then index_args[:what]
      end

      NoBrainer.run { self.table.index_create(index_name, index_args[:options], &index_proc) }
      NoBrainer.run { self.table.index_wait(index_name) } if options[:wait]
    end

    def perform_drop_index(index_name, options={})
      NoBrainer.run { self.table.index_drop(index_name) }
    end

    def perform_update_indexes(options={})
      current_indexes = NoBrainer.run { self.table.index_list }.map(&:to_sym)

      (current_indexes - self.indexes.keys).each do |index_name|
        perform_drop_index(index_name, options)
      end

      (self.indexes.keys - current_indexes).each do |index_name|
        perform_create_index(index_name, options)
      end
    end
  end
end
