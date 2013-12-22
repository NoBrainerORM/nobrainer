module NoBrainer::Criteria::Termination::Cache
  extend ActiveSupport::Concern

  included { attr_accessor :_with_cache }

  def with_cache
    chain { |criteria| criteria._with_cache = true }
  end

  def without_cache
    chain { |criteria| criteria._with_cache = false }
  end

  def merge!(criteria)
    super
    self._with_cache = criteria._with_cache unless criteria._with_cache.nil?
    self.reload
    self
  end

  def with_cache?
    @_with_cache.nil? ?  NoBrainer::Config.cache_documents : @_with_cache
  end

  def reload
    @cache = nil
  end

  def each(options={}, &block)
    return super unless with_cache? && !options[:no_cache] && block

    cache = []
    super(:no_cache => true) do |instance|
      block.call(instance)
      cache << instance
    end
    @cache = cache
  end

  def self.reload_on(*methods)
    methods.each do |method|
      define_method(method) do |*args, &block|
        super(*args, &block).tap { reload }
      end
    end
  end

  def self.use_cache_for(*methods)
    methods.each do |method|
      define_method(method) do |*args, &block|
        @cache ?  @cache.__send__(method, *args, &block) : super(*args, &block)
      end
    end
  end

  use_cache_for :first, :last, :count, :empty?, :any?
  reload_on :update_all, :destroy_all, :delete_all
end
