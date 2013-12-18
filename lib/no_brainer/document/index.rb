module NoBrainer::Document::Index
  extend ActiveSupport::Concern

  included do
    class_attribute :indexes
    self.indexes = {}
  end

  module ClassMethods
    def index(name, *args)
      indexes[name.to_sym] = args
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
      index_args = self.indexes[index_name].dup
      options = index_args.extract_options!

      index_proc = index_args.shift
      if index_proc
        raise "Too many arguments: #{index_args}" unless index_args.empty?
        if index_proc.is_a?(Array)
          index_fields = index_proc
          index_proc = ->(doc) { index_fields.map { |field| doc[field] } }
        end
        raise "Index argument must be a lambda or a list of fields" unless index_proc.is_a?(Proc)
      end

      NoBrainer.run { self.table.index_create(index_name, options, &index_proc) }

      if options[:wait]
        NoBrainer.run { self.table.index_wait(index_name) }
      end
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
