module NoBrainer::Criteria::Termination::EagerLoading
  extend ActiveSupport::Concern

  included { attr_accessor :_includes }

  def initialize(options={})
    super
    self._includes = []
  end

  def includes(*values)
    raise "Please enable caching with NoBrainer::Config.cache_documents = true" unless NoBrainer::Config.cache_documents
    chain(:keep_cache => true) { |criteria| criteria._includes = values }
  end

  def merge!(criteria, options={})
    super
    self._includes = self._includes + criteria._includes

    # XXX Not pretty hack
    if criteria._includes.present? && cached?
      perform_eager_loading(@cache)
    end
  end

  def each(options={}, &block)
    return super unless should_eager_load? && !options[:no_eager_loading] && block

    docs = []
    super(options.merge(:no_eager_loading => true)) { |doc| docs << doc }
    perform_eager_loading(docs)
    docs.each(&block)
    self
  end

  private

  def should_eager_load?
    self._includes.present? && !raw?
  end

  def get_one(criteria)
    super.tap { |doc| perform_eager_loading([doc]) }
  end

  def perform_eager_loading(docs)
    if should_eager_load? && docs.present?
      NoBrainer::Document::Association::EagerLoader.new.eager_load(docs, self._includes)
    end
  end
end
