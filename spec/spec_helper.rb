require 'rubygems'
require 'bundler'
Bundler.require

SPEC_ROOT = File.expand_path File.dirname(__FILE__)
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require f }

database_host = ENV['DB_HOST'] || 'localhost'
database_name = ENV['DB_NAME'] || 'nobrainer_test'
NoBrainer.configure do |config|
  config.rethinkdb_url = "rethinkdb://#{database_host}/#{database_name}"
end

# Silence some warning in I18n
I18n.enforce_available_locales = false rescue nil

RSpec.configure do |config|
  config.color_enabled = true
  config.include ModelsHelper
  config.include CallbacksHelper

  config.before(:each) do
    NoBrainer.purge!
    NoBrainer::Loader.cleanup
  end

  config.after do
  end
end
