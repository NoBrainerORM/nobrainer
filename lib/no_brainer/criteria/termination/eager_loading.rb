module NoBrainer::Criteria::Termination::EagerLoading
  extend ActiveSupport::Concern

  included { attr_accessor :_includes }

  def initialize(options={})
    super
    self._includes = []
  end

  def includes(*values)
    raise "Please enable caching with NoBrainer::Config.cache_documents = true" unless NoBrainer::Config.cache_documents
    chain { |criteria| criteria._includes += values }
  end

  def merge!(criteria)
    super
    self._includes = self._includes + criteria._includes
  end

  def each(options={}, &block)
    return super unless self._includes.present? && !options[:no_eager_loading] && block

    docs = []
    super(options.merge(:no_eager_loading => true)) { |doc| docs << doc }

    self._includes.uniq.each do |relation_name|
      relation = klass.relation_metadata[relation_name.to_sym]
      raise "Unknown relation #{relation_name}" unless relation
      relation.eager_load(docs)
    end

    docs.each(&block)
    self
  end
end
