class NoBrainer::Document::Index::MetaStore
  include NoBrainer::Document
  include NoBrainer::Document::Timestamps

  disable_perf_warnings

  default_scope ->{ order_by(:created_at) }

  store_in :database => ->{ Thread.current[:nobrainer_meta_store_db] },
           :table    => 'nobrainer_index_meta'

  field :table_name,   :type => String, :required => true
  field :index_name,   :type => String, :required => true
  field :rql_function, :type => String, :required => true

  def rql_function=(value)
    super(JSON.dump(value))
  end

  def rql_function
    JSON.load(super)
  end

  def self.on(db_name, &block)
    old_db_name = Thread.current[:nobrainer_meta_store_db]
    Thread.current[:nobrainer_meta_store_db] = db_name
    NoBrainer.with(:auto_create_tables => true) { block.call }
  ensure
    Thread.current[:nobrainer_meta_store_db] = old_db_name
  end
end
