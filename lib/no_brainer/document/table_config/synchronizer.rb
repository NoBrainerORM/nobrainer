class NoBrainer::Document::TableConfig::Synchronizer
  def initialize(models)
    @models = models
  end

  def sync_table_config(options={})
    # XXX A bit funny since we might touch the lock table...
    lock = NoBrainer::Lock.new('nobrainer:sync_table_config')

    lock.synchronize do
      @models.each(&:sync_table_config)
    end

    unless options[:wait] == false
      # Waiting on all models due to possible races
      @models.each(&:table_wait)
    end

    true
  end
end
