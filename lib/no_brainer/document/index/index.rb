class NoBrainer::Document::Index::Index < Struct.new(
    :model, :name, :aliased_name, :kind, :what, :external, :geo, :multi, :meta)

  MetaStore = NoBrainer::Document::Index::MetaStore

  def initialize(*args)
    super

    self.name = self.name.to_sym
    self.aliased_name = self.aliased_name.to_sym
    self.external = !!self.external
    # geo defaults for true with geo types.
    self.geo = !!model.fields[name].try(:[], :type).try(:<, NoBrainer::Geo::Base) if self.geo.nil?
    self.multi = !!self.multi
  end

  def same_definition?(other)
    # allow name to change through renames
    self.model == other.model &&
    self.geo == other.geo &&
    self.multi == other.multi &&
    self.serialized_rql_proc == other.serialized_rql_proc
  end

  def human_name
    index_name = "index #{model}.#{name}"
    index_name += " as #{aliased_name}" unless name == aliased_name
    index_name
  end

  def rql_proc
    case kind
      when :single   then ->(doc) { doc[model.lookup_field_alias(what)] }
      when :compound then ->(doc) { what.map { |field| doc[model.lookup_field_alias(field)] } }
      when :proc     then what # TODO XXX not translating the field aliases
    end
  end

  def serialized_rql_proc
    meta.try(:rql_function) || (rql_proc && NoBrainer::RQL.rql_proc_as_json(rql_proc))
  end

  def show_op(verb, options={})
    color = case verb
            when :create then "\e[1;32m" # green
            when :delete then "\e[1;31m" # red
            when :update then "\e[1;33m" # yellow
            end
    STDERR.puts "[NoBrainer] #{color}#{verb.to_s.capitalize} #{human_name}\e[0m" if options[:verbose]
  end

  def create(options={})
    show_op(:create, options)

    opt = {}
    opt[:multi] = true if multi
    opt[:geo] = true if geo

    NoBrainer::RQL.reset_lambda_var_counter
    NoBrainer.run(model.rql_table.index_create(aliased_name, opt, &rql_proc))

    MetaStore.on(model.database_name) do
      MetaStore.create(:table_name => model.table_name, :index_name => aliased_name,
                       :rql_function => serialized_rql_proc)
    end
  end

  def delete(options={})
    show_op(:delete, options)

    NoBrainer.run(model.rql_table.index_drop(aliased_name))

    MetaStore.on(model.database_name) do
      MetaStore.where(:table_name => model.table_name, :index_name => aliased_name).delete_all
    end
  end

  def update(wanted_index, options={})
    wanted_index.show_op(:update, options)

    self.delete(options.merge(:verbose => false))
    wanted_index.create(options.merge(:verbose => false))
  end
end
