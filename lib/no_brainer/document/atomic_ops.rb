module NoBrainer::Document::AtomicOps
  extend ActiveSupport::Concern

  class PendingAtomic
    attr_accessor :type

    def self._new(instance, field, value, is_user_value)
      type = instance.class.fields[field.to_sym].try(:[], :type)
      type ||= value.class unless value.nil?

      case
      when type == Array then PendingAtomicArray
      when type == Set   then PendingAtomicSet
      else self
      end.new(instance, field, value, is_user_value, type)
    end

    def initialize(instance, field, value, is_user_value, type)
      @instance = instance
      @field = field.to_s
      @value = value
      @is_user_value = is_user_value
      @type = type
      @ops = []
    end

    def default_value
      case
      when @type == Array   then []
      when @type == Set     then []
      when @type == Integer then 0
      when @type == Float   then 0.0
      when @type == String  then ""
      end
    end

    def initialize_copy(other)
      super
      @ops = @ops.dup
    end

    def to_s
      "<`#{@field}' with #{@ops.size} pending atomic operations>"
    end
    alias_method :inspect, :to_s

    def method_missing(method, *a, &b)
      if method == :<<
        method = :append
        modify_source!
      end

      @ops << [method, a, b]
      self
    end

    def compile_rql_value(rql_doc)
      field = @instance.class.lookup_field_alias(@field)
      value = @is_user_value ? RethinkDB::RQL.new.expr(@value) : rql_doc[field]
      value = value.default(default_value) if default_value
      @ops.reduce(value) { |v, (method, a, b)| v.__send__(method, *a, &b) }
    end

    def modify_source!
      unless @instance._is_attribute_touched?(@field)
        @instance.write_attribute(@field, self)
      end
    end
  end

  class PendingAtomicContainer < PendingAtomic; end

  class PendingAtomicArray < PendingAtomicContainer
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
      modify_source!
      self
    end
  end

  class PendingAtomicSet < PendingAtomicContainer
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
      modify_source!
      self
    end
  end

  def clear_dirtiness(options={})
    super
    @_touched_attributes = Set.new
  end

  def _touch_attribute(name)
    # The difference with dirty tracking and this is that dirty tracking does
    # not take into account fields that are set with their old value, whereas the
    # touched attribute does.
    @_touched_attributes << name.to_s
  end

  def _is_attribute_touched?(name)
    @_touched_attributes.include?(name.to_s)
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
    return value unless in_atomic?

    case value
    when PendingAtomicContainer then value
    when PendingAtomic then value.dup
    else PendingAtomic._new(self, name, value, _is_attribute_touched?(name))
    end
  end

  def _write_attribute(name, value)
    ensure_exclusive_atomic!

    case [in_atomic?, value.is_a?(PendingAtomic)]
    when [true, false]  then raise NoBrainer::Error::AtomicBlock.new('Avoid the use of atomic blocks for non atomic operations')
    when [false, true]  then raise NoBrainer::Error::AtomicBlock.new('Use atomic blocks for atomic operations')
    when [true, true]   then super.tap { _touch_attribute(name) }
    when [false, false] then super.tap { _touch_attribute(name) }
    end
  end

  def assign_attributes(attrs, options={})
    ensure_exclusive_atomic!
    super
  end

  def save?(options={})
    # TODO allow reload => true as an option to save+reload in a single op.
    raise NoBrainer::Error::AtomicBlock.new('You may persist documents only outside of queue_atomic blocks') if in_atomic?
    super.tap do |saved|
      if saved
        @_attributes.each do |attr, value|
          next unless value.is_a?(PendingAtomic)
          @_attributes[attr] = value.class.new(self, attr, nil, false, value.type)
        end
      end
    end
  end

  module ClassMethods
    def persistable_value(k, v, options={})
      v.is_a?(PendingAtomic) ? v.compile_rql_value(options[:rql_doc]) : super
    end
  end
end
