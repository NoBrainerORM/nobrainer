require 'nobrainer'

class NoBrainer::Railtie < Rails::Railtie
  config.app_generators.orm :nobrainer
  config.eager_load_namespaces << NoBrainer

  config.action_dispatch.rescue_responses.merge!(
    "NoBrainer::Error::DocumentNotFound" => :not_found,
    "NoBrainer::Error::DocumentInvalid"  => :unprocessable_entity,
    "NoBrainer::Error::InvalidType"      => :bad_request,
  )

  rake_tasks do
    load "no_brainer/railtie/database.rake"
  end

  console do
    # Send console messages to standard error like ActiveRecord.
    # Not the cleanest behavior, but if ActiveRecord does it, why not.
    unless defined?(ActiveRecord)
      console = ActiveSupport::Logger.new(STDERR)
      Rails.logger.extend ActiveSupport::Logger.broadcast(console)
    end
  end

  config.after_initialize do
    NoBrainer::Config.configure unless NoBrainer::Config.configured?

    (NoBrainer.rails5? ? ActiveSupport::Reloader : ActionDispatch::Reloader).to_prepare do
      NoBrainer::Loader.cleanup
    end
  end

  ActiveSupport.on_load(:action_controller) do
    require 'no_brainer/profiler/controller_runtime'
    include NoBrainer::Profiler::ControllerRuntime
  end
end
