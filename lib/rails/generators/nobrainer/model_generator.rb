require "rails/generators/nobrainer/namespace_fix"
require 'rails/generators/named_base'

module NoBrainer::Generators
  class ModelGenerator < Rails::Generators::NamedBase
    extend NoBrainer::Generators::NamespaceFix
    source_root File.expand_path("../../templates", __FILE__)

    argument(:attributes, :type => :array, default: [],
             banner: "field[:type][:index] ... field[:type][:index]")

    check_class_collision

    class_option :parent, :type => :string, :desc => "The parent class for the generated model"

    def create_model_file
      template "model.rb", File.join("app", "models", class_path, "#{file_name}.rb")
    end

    hook_for :test_framework
  end
end
