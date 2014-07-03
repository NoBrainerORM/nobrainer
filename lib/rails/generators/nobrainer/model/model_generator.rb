require "rails/generators/nobrainer"

module NoBrainer::Generators
  class ModelGenerator < Base
    argument(:attributes, :type => :array, default: [],
             banner: "field[:type][:index] ... field[:type][:index]")

    check_class_collision

    class_option :parent, :type => :string, :desc => "The parent class for the generated model"

    def create_model_file
      template "model.rb.tt", File.join("app/models", class_path, "#{file_name}.rb")
    end

    hook_for :test_framework
  end
end
