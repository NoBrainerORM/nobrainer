module NoBrainer::Criteria::Termination::Cache
  extend ActiveSupport::Concern

  included { attr_accessor :_without_cache }

  def without_cache
    chain { |criteria| criteria._without_cache = true }
  end

  def merge!(criteria)
    super
    self._without_cache = criteria._without_cache unless criteria._without_cache.nil?
    self.reload
    self
  end

  def without_cache?
    !!@_without_cache
  end

  def reload
    @cache = nil
  end

  def each(options={}, &block)
    return super if without_cache? || options[:no_cache] || !block

    cache = []
    super(:no_cache => true) do |instance|
      block.call(instance)
      cache << instance
    end
    @cache = cache
    self
  end

  def first(options={})
    @cache && options.empty? ? @cache.first : super
  end

  def last(options={})
    @cache && options.empty? ? @cache.last : super
  end

  def count
    @cache ? @cache.count : super
  end

  def empty?
    @cache ? @cache.empty? : super
  end

  def any?(&block)
    @cache ? @cache.any?(&block) : super
  end

  def update_all(*args, &block)
    super.tap { reload }
  end

  def destroy_all
    super.tap { reload }
  end

  def delete_all
    super.tap { reload }
  end
end
