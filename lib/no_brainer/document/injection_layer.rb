module NoBrainer::Document::InjectionLayer
  extend ActiveSupport::Concern

  module ClassMethods
    def inject_in_layer(name, code=nil, file=nil, line=nil, &block)
      mod = class_eval "module NoBrainerLayer; module #{name.to_s.camelize}; self; end; end"
      mod.module_eval(code, file, line) if code
      mod.module_exec(&block) if block
      include mod
    end
  end
end
