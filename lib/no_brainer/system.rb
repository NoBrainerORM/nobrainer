module NoBrainer::System
  extend NoBrainer::Autoload
  autoload :Document, :ClusterConfig, :DBConfig,
           :Issue, :Job, :Log, :ServerConfig, :ServerStatus,
           :Stat, :TableConfig, :TableStatus

  # A few shortcuts to make user's life easier
  def self.const_missing(const_name)
    mapping = {:CurrentIssues => :Issue,
               :CurrentIssue  => :Issue,
               :Issues        => :Issue,
               :Jobs          => :Job,
               :Logs          => :Log,
               :Stats         => :Stat}
    const_get(mapping[const_name] || const_name)
  end
end
