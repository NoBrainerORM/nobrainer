require "nobrainer"
require "rails"

class NoBrainer::Railtie < Rails::Railtie
  config.action_dispatch.rescue_responses.merge!(
    "NoBrainer::Errors::DocumentNotFound" => :not_found,
    "NoBrainer::Errors::DocumentInvalid"  => :unprocessable_entity,
    "NoBrainer::Errors::DocumentNotSaved" => :unprocessable_entity,
  )

  rake_tasks do
    load "no_brainer/railtie/database.rake"
  end

  config.after_initialize do
    ActionDispatch::Reloader.to_cleanup do
      NoBrainer::Loader.cleanup
    end
  end

  #config.eager_load_namespaces << NoBrainer
end
