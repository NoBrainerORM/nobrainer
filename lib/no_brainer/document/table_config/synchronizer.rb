class NoBrainer::Document::TableConfig::Synchronizer
  def initialize(models)
    @models = models
  end

  def sync_table_config(options={})
    @models.each(&:sync_table_config)

    unless options[:wait] == false
      # Waiting on all models due to possible races
      @models.each(&:table_wait)
    end

    true
  end
end
