class NoBrainer::System::TableConfig
  include NoBrainer::System::Document

  field :db
  field :name
  field :durability
  field :primary_key
  field :shards
  field :write_acks
  field :indexes
end
