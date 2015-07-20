class NoBrainer::System::Issue
  include NoBrainer::System::Document

  table_config :name => 'current_issues'

  field :type
  field :critical
  field :info
  field :description
end
