class NoBrainer::Document::Index::MetaStore
  include NoBrainer::Document
  include NoBrainer::Document::Timestamps

  disable_perf_warnings

  default_scope ->{ order_by(:created_at) }

  table_config :name => 'nobrainer_index_meta'

  field :table_name,   :type => String, :required => true
  field :index_name,   :type => String, :required => true
  field :rql_function, :type => Text,   :required => true

  def rql_function=(value)
    super(JSON.dump(value))
  end

  def rql_function
    JSON.load(super)
  end
end
