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
    NoBrainer::Config.configure unless NoBrainer::Config.configured?

    if defined?(ActiveRecord) && NoBrainer::Config.warn_on_active_record
      STDERR.puts "[NoBrainer] WARNING: ActiveRecord is loaded which is probably not what you want."
      STDERR.puts "[NoBrainer] Follow the instructions on http://todo/ to learn how to remove ActiveRecord."
      STDERR.puts "[NoBrainer] Configure NoBrainer with 'config.warn_on_active_record = false' to disable with warning."
    end

    ActionDispatch::Reloader.to_cleanup do
      NoBrainer::Loader.cleanup
    end
  end

  #config.eager_load_namespaces << NoBrainer
end
