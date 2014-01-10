module NoBrainer::Document::InjectionLayer
  extend ActiveSupport::Concern

  module ClassMethods
    def inject_in_layer(name, &block)
      mod = class_eval "module NoBrainerLayer; module #{name.to_s.camelize}; self; end; end"
      mod.module_exec(&block)
      include mod
    end
  end
end
