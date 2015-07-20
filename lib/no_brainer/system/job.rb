class NoBrainer::System::Job
  include NoBrainer::System::Document

  table_config :name => 'jobs'

  field :duration_sec
  field :info
  field :servers
  field :type
end
