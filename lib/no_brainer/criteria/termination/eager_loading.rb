module NoBrainer::Criteria::Termination::EagerLoading
  extend ActiveSupport::Concern

  included { attr_accessor :_includes }

  def initialize(options={})
    super
    self._includes = []
  end

  def includes(*values)
    raise "Please enable caching with NoBrainer::Config.cache_documents = true" unless NoBrainer::Config.cache_documents
    chain { |criteria| criteria._includes = values }
  end

  def merge!(criteria)
    super
    self._includes = self._includes + criteria._includes
  end

  def each(options={}, &block)
    return super unless should_eager_load? && !options[:no_eager_loading] && block

    docs = []
    super(options.merge(:no_eager_loading => true)) { |doc| docs << doc }
    eager_load(docs, self._includes)
    docs.each(&block)
    self
  end

  private

  def should_eager_load?
    self._includes.present? && !raw?
  end

  def get_one(criteria)
    super.tap { |doc| eager_load([doc], self._includes) if should_eager_load? }
  end

  def eager_load_relation(docs, relation_name)
    docs = docs.compact
    return if docs.empty?
    relation = docs.first.root_class.relation_metadata[relation_name.to_sym]
    raise "Unknown relation #{relation_name}" unless relation
    relation.eager_load(docs)
  end

  def eager_load(docs, includes)
    case includes
    when Hash  then includes.each { |k,v| eager_load(eager_load_relation(docs, k), v) }
    when Array then includes.each { |v| eager_load(docs, v) }
    else eager_load_relation(docs, includes)
    end
  end
end
