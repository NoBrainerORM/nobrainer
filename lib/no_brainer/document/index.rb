module NoBrainer::Document::Index
  VALID_INDEX_OPTIONS = [:multi, :as]
  extend ActiveSupport::Concern

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
        when nil   then [:single,   name.to_sym]
        when Array then [:compound, args.first.map(&:to_sym)]
        when Proc  then [:proc,     args.first]
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

      indexes[name] = {:kind => kind, :what => what, :as => as, :options => options}
    end

    def remove_index(name)
      indexes.delete(name.to_sym)
    end

    def has_index?(name)
      !!indexes[name.to_sym]
    end

    def lookup_index_alias(attr)
      indexes[attr.to_sym].try(:[], :as) || attr
    end

    def _field(attr, options={})
      if has_index?(attr) && indexes[attr][:kind] != :single
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
      super
      remove_index(attr) if fields[attr][:index]
    end

    def perform_create_index(index_name, options={})
      index_name = index_name.to_sym
      index_args = self.indexes[index_name]
      aliased_name = index_args[:as]

      index_proc = case index_args[:kind]
        when :single   then ->(doc) { doc[lookup_field_alias(index_name)] }
        when :compound then ->(doc) { index_args[:what].map { |field| doc[lookup_field_alias(field)] } }
        when :proc     then index_args[:what]
      end

      NoBrainer.run(self.rql_table.index_create(aliased_name, index_args[:options], &index_proc))
      wait_for_index(index_name) unless options[:wait] == false

      readable_index_name = "index #{self}.#{index_name}"
      readable_index_name += " as #{aliased_name}" unless index_name == aliased_name

      STDERR.puts "Created index #{readable_index_name}" if options[:verbose]
    end

    def perform_drop_index(index_name, options={})
      index_name = index_name.to_sym
      aliased_name = self.indexes[index_name].try(:[], :as) || index_name

      readable_index_name = "index #{self}.#{index_name}"
      readable_index_name += " as #{aliased_name}" unless index_name == aliased_name

      if STDIN.stat.chardev? && STDERR.stat.chardev? && !options[:no_confirmation]
        STDERR.print "Confirm dropping #{readable_index_name} [yna]: "
        case STDIN.gets.strip.chomp
        when 'y' then
        when 'n' then return
        when 'a' then options[:no_confirmation] = true
        end
      end

      NoBrainer.run(self.rql_table.index_drop(aliased_name))
      STDERR.puts "Dropped #{readable_index_name}" if options[:verbose]
    end

    def get_index_alias_reverse_map
      Hash[self.indexes.map { |k,v| [v[:as], k] }].tap do |mapping|
        raise "Detected clashing index aliases" if mapping.count != self.indexes.count
      end
    end

    def perform_update_indexes(options={})
      alias_mapping = self.get_index_alias_reverse_map
      current_indexes = NoBrainer.run(self.rql_table.index_list).map do |index|
        alias_mapping[index.to_sym] || index.to_sym
      end
      wanted_indexes = self.indexes.keys - [self.pk_name]

      # FIXME removing an aliased field is not going to work well with this method

      (current_indexes - wanted_indexes).each do |index_name|
        perform_drop_index(index_name, options)
      end

      (wanted_indexes - current_indexes).each do |index_name|
        perform_create_index(index_name, options)
      end
    end
    alias_method :update_indexes, :perform_update_indexes

    def wait_for_index(index_name=nil, options={})
      args = [index_name].compact
      NoBrainer.run(self.rql_table.index_wait(*args))
    end
  end
end
