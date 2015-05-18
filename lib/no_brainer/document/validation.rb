module NoBrainer::Document::Validation
  extend NoBrainer::Autoload
  extend ActiveSupport::Concern

  autoload_and_include :Core, :Uniqueness, :NotNull
end
