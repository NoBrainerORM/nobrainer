require 'rails/generators/named_base'
require 'nobrainer'

module NoBrainer::Generators
  class Base < Rails::Generators::NamedBase
    def self.base_name
      'nobrainer'
    end

    def self.base_root
      File.dirname(__FILE__)
    end

    def self.namespace
      super.gsub(/no_brainer/, 'nobrainer')
    end
  end
end
