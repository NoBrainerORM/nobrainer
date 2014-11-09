module NoBrainer::Criteria::Core
  extend ActiveSupport::Concern

  included do
    singleton_class.send(:attr_accessor, :options_definitions)
    self.options_definitions = {}
    attr_accessor :options

    criteria_option :model, :merge_with => :set_scalar
    criteria_option :finalized, :merge_with => :set_scalar
  end

  def initialize(options={})
    @options = options
  end

  def dup
    # We don't keep any of the instance variables except options.
    self.class.new(@options.dup)
  end

  def model
    @options[:model]
  end

  def to_rql
    finalized_criteria.__send__(:compile_rql_pass2)
  end

  def inspect
    # rescue super because sometimes model is not set.
    to_rql.inspect rescue super
  end

  def run(&block)
    block ||= proc { to_rql }
    NoBrainer.run(:criteria => self, &block)
  end

  def merge!(criteria, options={})
    criteria.options.each do |k,v|
      merge_proc = self.class.options_definitions[k]
      raise "Non declared option: #{k}" unless merge_proc
      @options[k] = merge_proc.call(@options[k], v)
    end
    self
  end

  def merge(criteria, options={})
    dup.tap { |new_criteria| new_criteria.merge!(criteria, options) }
  end

  def ==(other)
    return to_a == other if other.is_a?(Array)
    super
  end

  private

  def chain(options={}, merge_options={})
    merge(self.class.new(options), merge_options)
  end

  def compile_rql_pass1
    # This method is overriden by other modules.
    raise "Criteria not bound to a model" unless model
    model.rql_table
  end

  def compile_rql_pass2
    # This method is overriden by other modules.
    compile_rql_pass1
  end

  def finalized?
    !!@options[:finalized]
  end

  def finalized_criteria
    @finalized_criteria ||= finalized? ? self : self.class._finalize_criteria(self)
  end

  module ClassMethods
    def criteria_option(*names)
      options = names.extract_options!

      names.map(&:to_sym).each do |name|
        merge_proc = options[:merge_with]
        merge_proc = MergeStrategies.method(merge_proc) if merge_proc.is_a?(Symbol)
        self.options_definitions[name] = merge_proc
      end
    end

    def _finalize_criteria(base)
      base.__send__(:chain, :finalized => true)
    end
  end

  module MergeStrategies
    extend self
    def set_scalar(a, b)
      b
    end

    def merge_hash(a, b)
      a ? a.merge(b) : b
    end

    def append_array(a, b)
      a ? a+b : b
    end
  end
end
