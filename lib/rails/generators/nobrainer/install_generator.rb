require "rails/generators/nobrainer/namespace_fix"
require 'rails/generators/base'

module NoBrainer::Generators
  class InstallGenerator < Rails::Generators::Base
    extend NoBrainer::Generators::NamespaceFix
    source_root File.expand_path("../../templates", __FILE__)

    desc "Disable ActiveRecord and generates ./config/initializer/nobrainer.rb"

    class RequireProxy
      attr_accessor :required_paths
      def initialize
        self.required_paths = []
      end

      def require(path)
        self.required_paths << path
      end

      def resolve_require_path(path)
        $:.map { |dir| File.join(dir, path) }.detect { |f| File.exists?(f) }
      end
    end

    def expand_rails_all
      require_proxy = RequireProxy.new
      rails_all_file = require_proxy.resolve_require_path('rails/all.rb')
      require_proxy.instance_eval(File.read(rails_all_file))

      gsub_file('config/application.rb', %r(^require 'rails/all'$)) do
        require_proxy.required_paths.map { |f| "require '#{f}'" }.join("\n")
      end
    end

    def remove_active_record
      (Dir['config/environments/*'] + ['config/application.rb']).each do |config_file|
        comment_lines(config_file, /active_record/)
      end
    end


    def copy_initializer
      template('nobrainer.rb', 'config/initializer/nobrainer.rb')
    end
  end
end
