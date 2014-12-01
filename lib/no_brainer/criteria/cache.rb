module NoBrainer::Criteria::Cache
  extend ActiveSupport::Concern

  included { criteria_option :with_cache, :merge_with => :set_scalar }

  def with_cache
    chain(:with_cache => true)
  end

  def without_cache
    chain(:with_cache => false)
  end

  def inspect
    msg = super
    msg = "#{msg} \e[1;37m# #{@cache.size} results cached\e[0m" if @cache && with_cache?
    msg
  end

  def merge!(criteria, options={})
    if options[:copy_cache_from] && options[:copy_cache_from].cached?
      @cache = options[:copy_cache_from].instance_variable_get(:@cache)
    end
    super
  end

  def with_cache?
    finalized_criteria.options[:with_cache] != false
  end

  def reload
    @cache = nil
  end

  def cached?
    !!@cache
  end

  def each(options={}, &block)
    return super unless with_cache? && !options[:no_cache] && block
    return @cache.each(&block) if @cache

    cache = []
    super(options.merge(:no_cache => true)) do |instance|
      block.call(instance)
      cache << instance
    end
    @cache = cache
    self
  end

  def _override_cache(cache)
    @cache = cache
  end

  def self.use_cache_for(*methods)
    methods.each do |method|
      define_method(method) do |*args, &block|
        @cache ? @cache.__send__(method, *args, &block) : super(*args, &block)
      end
    end
  end

  def self.reload_on(*methods)
    methods.each do |method|
      define_method(method) do |*args, &block|
        reload
        super(*args, &block).tap { reload }
      end
    end
  end

  use_cache_for :first, :last, :count, :empty?, :any?
  reload_on :update_all, :destroy_all, :delete_all
end
