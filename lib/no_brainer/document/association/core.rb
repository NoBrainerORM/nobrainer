module NoBrainer::Document::Association::Core
  extend ActiveSupport::Concern

  module Metadata
    extend ActiveSupport::Concern

    attr_accessor :owner_model, :target_name, :options

    def initialize(owner_model, target_name, options={})
      @owner_model = owner_model
      @target_name = target_name
      @options = options
    end

    def association_model
      @association_model ||= self.class.name.deconstantize.constantize
    end

    def new(owner)
      association_model.new(self, owner)
    end

    def delegate(method_src, method_dst, options={})
      metadata = self
      owner_model.inject_in_layer :associations do
        define_method(method_src) do |*args, &block|
          super(*args, &block) if options[:call_super]
          target = options[:to] == :self ? self : associations[metadata]
          target.__send__(method_dst, *args, &block)
        end
      end
    end

    def hook
      options.assert_valid_keys(*self.class.const_get(:VALID_OPTIONS))
      delegate("#{target_name}=", :write)
      delegate("#{target_name}", :read)
    end

    def add_callback_for(what)
      instance_eval <<-RUBY, __FILE__, __LINE__ + 1
        if !@added_#{what}
          metadata = self
          owner_model.#{what} { associations[metadata].#{what}_callback }
          @added_#{what} = true
        end
      RUBY
    end
  end

  included { attr_accessor :metadata, :owner }

  delegate(:primary_key, :foreign_key, :target_name, :target_model, :base_criteria,
           :polymorphic?, :polymorphic_type_field, :as,
           :to => :metadata)

  def initialize(metadata, owner)
    @metadata, @owner = metadata, owner
  end

  def assert_target_type(value)
    unless value.is_a?(target_model) || value.nil?
      options = { :attr_name => target_name, :value => value, :type => target_model }
      raise NoBrainer::Error::InvalidType.new(options)
    end
  end
end
