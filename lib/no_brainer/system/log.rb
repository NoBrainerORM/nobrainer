class NoBrainer::System::Log
  include NoBrainer::System::Document

  table_config :name => 'logs'

  field :level
  field :message
  field :server
  field :timestamp
  field :uptime
end
