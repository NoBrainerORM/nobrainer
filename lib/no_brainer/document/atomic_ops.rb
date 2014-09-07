module NoBrainer::Document::AtomicOps
  extend ActiveSupport::Concern

  class PendingAtomic
    def initialize(instance, field, orig_value, options={})
      @instance = instance
      @field = field
      @orig_value = orig_value
      @options = options
      @ops = []
    end

    def write_access?
      @options[:write_access] == true
    end

    def ensure_writeable!
      unless write_access?
        @options[:write_access] = true
        @instance.write_attribute(@field, self)
      end
    end

    def to_s
      "<#{@field} with pending atomic operations>"
    end
    alias inspect to_s

    def method_missing(method_name, *a, &b)
      @ops << [method_name, a, b]
      self
    end

    def <<(value)
      method = @orig_value.is_a?(Set) ? :set_insert : :append
      @ops << [method, value]
      ensure_writeable!
      self
    end

    def compile_rql_value(rql_doc)
      field = @instance.class.lookup_field_alias(@field)
      value = rql_doc[field]
      @ops.each { |method_name, a, b| value = value.__send__(method_name, *a, &b) }
      value
    end
  end

  def queue_atomic(&block)
    old_atomic, Thread.current[:nobrainer_atomic] = Thread.current[:nobrainer_atomic], true
    block.call(RethinkDB::RQL.new)
  ensure
    Thread.current[:nobrainer_atomic] = old_atomic
  end

  def in_atomic?
    !!Thread.current[:nobrainer_atomic]
  end

  def _read_attribute(name)
    value = super
    case [in_atomic?, value.is_a?(PendingAtomic)]
    when [true, true]   then value
    when [true, false]  then PendingAtomic.new(self, name.to_s, value, :write_access => false)
    when [false, true]  then raise NoBrainer::Error::CannotReadAtomic.new(self, name, value)
    when [false, false] then value
    end
  end

  def read_attribute_for_change(attr)
    super
  rescue NoBrainer::Error::CannotReadAtomic => e
    e.value
  end

  module ClassMethods
    def persistable_value(k, v, options={})
      v.is_a?(PendingAtomic) ? v.compile_rql_value(options[:rql_doc]) : super
    end
  end
end
