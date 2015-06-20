module NoBrainer::Generators
  module NamespaceFix
    def base_name
      'nobrainer'
    end

    def base_root
      File.dirname(__FILE__)
    end

    def namespace
      super.gsub(/no_brainer/, 'nobrainer')
    end
  end
end
