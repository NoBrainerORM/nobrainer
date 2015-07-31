module NoBrainer::Criteria::EagerLoad
  extend ActiveSupport::Concern

  included { criteria_option :eager_load, :merge_with => :append_array }

  def eager_load(*values)
    chain({:eager_load => values}, :copy_cache_from => self)
  end

  def preload(*values)
    STDERR.puts "[NoBrainer] `preload' is deprecated and will be removed, please use `eager_load' instead"
    eager_load(*values)
  end

  def merge!(criteria, options={})
    super.tap do
      # If we already have some cached documents, and we need to so some eager
      # loading, then we do it now. It's easier than doing it lazily.
      if self.cached? && criteria.options[:eager_load].present?
        perform_eager_load(@cache)
      end
    end
  end

  def each(options={}, &block)
    return super unless should_eager_load? && !options[:no_eager_loading] && block

    docs = []
    super(options.merge(:no_eager_loading => true)) { |doc| docs << doc }
    # TODO batch the eager loading with NoBrainer::Config.criteria_cache_max_entries
    perform_eager_load(docs)
    docs.each(&block)
    self
  end

  private

  def should_eager_load?
    @options[:eager_load].present? && !raw?
  end

  def get_one(criteria)
    super.tap { |doc| perform_eager_load([doc]) }
  end

  def perform_eager_load(docs)
    if should_eager_load? && docs.present?
      NoBrainer::Document::Association::EagerLoader.eager_load(docs, @options[:eager_load])
    end
  end
end
