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

    def new(owner)
      association_klass.new(self, owner)
    end

    def delegate(method_name, target, options={})
      metadata = self
      owner_klass.inject_in_layer :associations do
        define_method(method_name) do |*args, &block|
          super(*args, &block) if options[:call_super]
          associations[metadata].__send__(target, *args, &block)
        end
      end
    end

    def hook
      options.assert_valid_keys(*self.class.const_get(:VALID_OPTIONS))
      delegate("#{target_name}=", :write)
      delegate("#{target_name}", :read)
    end

    def add_callback_for(what)
      instance_eval <<-RUBY, __FILE__, __LINE__+1
        if !@added_#{what}
          metadata = self
          owner_klass.#{what} { associations[metadata].#{what}_callback }
          @added_#{what} = true
        end
      RUBY
    end
  end

  included { attr_accessor :metadata, :owner }

  delegate :primary_key, :foreign_key, :target_name, :target_klass, :to => :metadata

  def initialize(metadata, owner)
    @metadata, @owner = metadata, owner
  end

  def assert_target_type(value)
    unless value.is_a?(target_klass) || value.nil?
      options = { :attr_name => target_name, :value => value, :type => target_klass }
      raise NoBrainer::Error::InvalidType.new(options)
    end
  end
end
