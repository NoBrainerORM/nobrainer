module NoBrainer::Document::Association::Core
  extend ActiveSupport::Concern

  module Metadata
    extend ActiveSupport::Concern

    attr_accessor :owner_klass, :target_name, :options

    def initialize(owner_klass, target_name, options={})
      @owner_klass = owner_klass
      @target_name = target_name
      @options = options
    end

    def association_klass
      @association_klass ||= self.class.name.deconstantize.constantize
    end

    def new(instance)
      association_klass.new(self, instance)
    end

    def delegate(method_name, target, options={})
      metadata = self
      owner_klass.inject_in_layer :associations do
        define_method(method_name) do |*args, &block|
          super(*args, &block) if options[:call_super]
          association(metadata).__send__(target, *args, &block)
        end
      end
    end

    def hook
      delegate("#{target_name}=", :write)
      delegate("#{target_name}", :read)
    end

    def add_callback_for(what)
      instance_eval <<-RUBY, __FILE__, __LINE__+1
        if !@added_#{what}
          metadata = self
          owner_klass.#{what} { association(metadata).#{what}_callback }
          @added_#{what} = true
        end
      RUBY
    end
  end

  included { attr_accessor :metadata, :instance }

  delegate :foreign_key, :target_name, :target_klass, :to => :metadata

  def initialize(metadata, instance)
    @metadata = metadata
    @instance = instance
  end

  def assert_target_type(value)
    unless value.is_a?(target_klass) || value.nil?
      msg = "Trying to use a #{value.class} as a #{target_name}"
      raise NoBrainer::Error::InvalidType.new(msg)
    end
  end
end
