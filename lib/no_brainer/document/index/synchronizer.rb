class NoBrainer::Document::Index::Synchronizer
  Index = NoBrainer::Document::Index::Index
  MetaStore = NoBrainer::Document::Index::MetaStore

  def initialize(models)
    @models_indexes_map = Hash[models.map do |model|
      [model, model.indexes.values.reject { |index| index.name == model.pk_name }]
    end]
  end

  def meta_store
    @meta_store ||= MetaStore.to_a
  end

  class Op < Struct.new(:index, :op, :args)
    def run(options={})
      index.__send__(op, *args, options)
    end
  end

  def _generate_plan_for(model, wanted_indexes)
    current_indexes = NoBrainer.run(model.rql_table.index_status).map do |s|
      meta = meta_store.select { |i| i.table_name == model.table_name && i.index_name == s['index'] }.last
      Index.new(model, s['index'], s['index'], nil, nil, nil, s['geo'], s['multi'], meta)
    end

    all_aliased_names = (wanted_indexes + current_indexes).map(&:aliased_name).uniq
    all_aliased_names.map do |aliased_name|
      wanted_index = wanted_indexes.select { |i| i.aliased_name == aliased_name }.first
      current_index = current_indexes.select { |i| i.aliased_name == aliased_name }.first

      next if wanted_index.try(:external)

      case [!wanted_index.nil?, !current_index.nil?]
      when [true, false] then Op.new(wanted_index, :create)
      when [false, true] then Op.new(current_index, :delete)
      when [true, true]  then
        case wanted_index.same_definition?(current_index)
        when true  then nil # up to date
        when false then Op.new(current_index, :update, [wanted_index])
        end
      end
    end.compact
  end

  def generate_plan
    @models_indexes_map.flat_map { |model, indexes| _generate_plan_for(model, indexes) }
  end

  def sync_indexes(options={})
    lock = NoBrainer::Lock.new('nobrainer:sync_indexes')

    lock.synchronize do
      plan = generate_plan
      plan.each { |op| lock.refresh; op.run(options) }
    end

    unless options[:wait] == false
      # Waiting on all models due to possible races when performing concurrent
      # sync_indexes()
      @models_indexes_map.each_key do |model|
        NoBrainer.run(model.rql_table.index_wait())
      end
    end

    true
  end

  class << self
    def instance
      new(NoBrainer::Document.all)
    end

    delegate :sync_indexes, :to => :instance
  end
end
