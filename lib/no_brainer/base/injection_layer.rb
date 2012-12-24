module NoBrainer::Base::InjectionLayer
  extend ActiveSupport::Concern

  module ClassMethods
    def inject_in_layer(name, code, file, line)
      class_eval <<-RUBY, file, line
        include module NoBrainerLayer; module #{name.to_s.camelize}; #{code}; self; end; end
      RUBY
    end
  end
end
