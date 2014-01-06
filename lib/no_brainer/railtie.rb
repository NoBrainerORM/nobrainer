require 'nobrainer'

class NoBrainer::Railtie < Rails::Railtie
  config.app_generators.orm :nobrainer
  config.eager_load_namespaces << NoBrainer

  config.action_dispatch.rescue_responses.merge!(
    "NoBrainer::Errors::DocumentNotFound" => :not_found,
    "NoBrainer::Errors::DocumentInvalid"  => :unprocessable_entity,
  )

  rake_tasks do
    load "no_brainer/railtie/database.rake"
  end

  config.after_initialize do
    NoBrainer::Config.configure unless NoBrainer::Config.configured?

    if defined?(ActiveRecord) && NoBrainer::Config.warn_on_active_record
      STDERR.puts "[NoBrainer] WARNING: ActiveRecord is loaded which is probably not what you want."
      STDERR.puts "[NoBrainer] Follow the instructions on http://nobrainer.io/docs/configuration/#removing_activerecord"
      STDERR.puts "[NoBrainer] Configure NoBrainer with 'config.warn_on_active_record = false' to disable with warning."
    end

    if defined?(Mongoid)
      STDERR.puts "[NoBrainer] WARNING: Mongoid is loaded, and we conflict on the symbol decorations"
      STDERR.puts "[NoBrainer] They are used in queries like Model.where(:tags.in => ['fun', 'stuff'])"
      STDERR.puts "[NoBrainer] This is a problem!"
    end

    ActionDispatch::Reloader.to_cleanup do
      NoBrainer::Loader.cleanup
    end
  end
end
