module NoBrainer::Criteria::Preload
  extend ActiveSupport::Concern

  included { attr_accessor :_preloads }

  def initialize(options={})
    super
    self._preloads = []
  end

  def preload(*values)
    chain(:keep_cache => true) { |criteria| criteria._preloads = values }
  end

  def includes(*values)
    NoBrainer.logger.warn "[NoBrainer] includes() is deprecated and will be removed, use preload() instead."
    preload(*values)
  end

  def merge!(criteria, options={})
    super
    self._preloads = self._preloads + criteria._preloads

    # XXX Not pretty hack
    if criteria._preloads.present? && cached?
      perform_preloads(@cache)
    end
  end

  def each(options={}, &block)
    return super unless should_preloads? && !options[:no_preloading] && block

    docs = []
    super(options.merge(:no_preloading => true)) { |doc| docs << doc }
    perform_preloads(docs)
    docs.each(&block)
    self
  end

  private

  def should_preloads?
    self._preloads.present? && !raw?
  end

  def get_one(criteria)
    super.tap { |doc| perform_preloads([doc]) }
  end

  def perform_preloads(docs)
    if should_preloads? && docs.present?
      NoBrainer::Document::Association::EagerLoader.new.eager_load(docs, self._preloads)
    end
  end
end
