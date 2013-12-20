module NoBrainer::Document::Relation::Core
  extend ActiveSupport::Concern

  included { attr_accessor :metadata, :instance }

  def initialize(metadata, instance)
    @metadata = metadata
    @instance = instance
  end

  module Metadata
    extend ActiveSupport::Concern

    attr_accessor :lhs_klass, :rhs_name, :options

    def initialize(lhs_klass, rhs_name, options={})
      @lhs_klass = lhs_klass
      @rhs_name = rhs_name
      @options = options
    end

    def relation_klass
      @relation_klass ||= self.class.name.deconstantize.constantize
    end

    def new(instance)
      relation_klass.new(self, instance)
    end

    def delegate(method_name, target, options={})
      metadata = self
      lhs_klass.inject_in_layer :relations do
        define_method(method_name) do |*args, &block|
          super(*args, &block) if options[:call_super]
          relation(metadata).__send__(target, *args, &block)
        end
      end
    end
  end
end
