class NoBrainer::System::Stat
  include NoBrainer::System::Document

  table_config :name => 'stats'

  field :server
  field :db
  field :table
  field :query_engine
  field :storage_engine
end
