module NoBrainer::Document::AtomicOps
  extend ActiveSupport::Concern

  class PendingAtomic
    def self._new(instance, field, user_value, options={})
      klass = case user_value
              when Array then PendingAtomicArray
              when Set   then PendingAtomicSet
              else self
              end
      klass.new(instance, field, user_value, options)
    end

    def initialize(instance, field, user_value, options={})
      @instance = instance
      @field = field
      @user_value = user_value
      @value_tainted = instance._is_attribute_tainted?(field)
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

    def compile_rql_value(rql_doc)
      field = @instance.class.lookup_field_alias(@field)
      value = @value_tainted ? RethinkDB::RQL.new.expr(@user_value) : rql_doc[field]
      @ops.each { |method_name, a, b| value = value.__send__(method_name, *a, &b) }
      value
    end
  end

  class PendingAtomicArray < PendingAtomic
    def -(value)
      @ops << [:difference, [value.to_a]]
      self
    end
    def difference(v); self - v; end

    def delete(value)
      difference([value])
    end

    def +(value)
      @ops << [:+, [value.to_a]]
      self
    end
    def add(v); self + v; end

    def &(value)
      @ops << [:set_intersection, [value.to_a]]
      self
    end
    def intersection(v); self & v; end

    def |(value)
      @ops << [:set_union, [value.to_a]]
      self
    end
    def union(v); self | v; end

    def <<(value)
      @ops << [:append, [value]]
      ensure_writeable!
      self
    end
  end

  class PendingAtomicSet < PendingAtomicArray
    def -(value)
      @ops << [:set_difference, [value.to_a]]
      self
    end

    def +(value)
      @ops << [:set_union, [value.to_a]]
      self
    end

    def <<(value)
      @ops << [:set_union, [[value]]]
      ensure_writeable!
      self
    end
  end

  def clear_dirtiness(options={})
    super
    @_tainted_attributes = Set.new
  end

  def _taint_attribute(name)
    @_tainted_attributes << name
  end

  def _is_attribute_tainted?(name)
    @_tainted_attributes.include?(name)
  end

  def in_atomic?
    !!Thread.current[:nobrainer_atomic]
  end

  def in_other_atomic?
    v = Thread.current[:nobrainer_atomic]
    !v.nil? && !v.equal?(self)
  end

  def ensure_exclusive_atomic!
    raise NoBrainer::Error::AtomicBlock.new('You may not access other documents within an atomic block') if in_other_atomic?
  end

  def queue_atomic(&block)
    ensure_exclusive_atomic!

    begin
      old_atomic, Thread.current[:nobrainer_atomic] = Thread.current[:nobrainer_atomic], self
      block.call(RethinkDB::RQL.new)
    ensure
      Thread.current[:nobrainer_atomic] = old_atomic
    end
  end

  def _read_attribute(name)
    ensure_exclusive_atomic!
    value = super

    case [in_atomic?, value.is_a?(PendingAtomic)]
    when [true, true]   then value
    when [true, false]  then PendingAtomic._new(self, name.to_s, value, :write_access => false)
    when [false, true]  then raise NoBrainer::Error::CannotReadAtomic.new(self, name, value)
    when [false, false] then value
    end
  end

  def _write_attribute(name, value)
    ensure_exclusive_atomic!

    case [in_atomic?, value.is_a?(PendingAtomic)]
    when [true, true]   then super
    when [true, false]  then raise NoBrainer::Error::AtomicBlock.new('Avoid the use of atomic blocks for non atomic operations')
    when [false, true]  then raise NoBrainer::Error::AtomicBlock.new('Use atomic blocks for atomic operations')
    when [false, false] then super.tap { _taint_attribute(name.to_s) }
    end
  end

  def assign_attributes(attrs, options={})
    ensure_exclusive_atomic!
    super
  end

  def save?(options={})
    raise NoBrainer::Error::AtomicBlock.new('You may persist documents only outside of queue_atomic blocks') if in_atomic?
    super
  end

  def read_attribute_for_change(attr)
    super
  rescue NoBrainer::Error::CannotReadAtomic => e
    e.value
  end

  def read_attribute_for_validation(attr)
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

class ActiveModel::EachValidator
  # XXX Monkey Patching :(
  def validate(record)
    attributes.each do |attribute|
      value = record.read_attribute_for_validation(attribute)
      next if value.is_a?(NoBrainer::Document::AtomicOps::PendingAtomic) # <--- This is the added line
      next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
      validate_each(record, attribute, value)
    end
  end
end
