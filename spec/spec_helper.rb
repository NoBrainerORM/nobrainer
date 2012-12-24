require 'rubygems'
require 'bundler'
Bundler.require

Dir["./spec/support/**/*.rb"].each { |f| require f }

database_name = 'nobrainer_test'
NoBrainer.connect "rethinkdb://localhost/#{database_name}"

RSpec.configure do |config|
  config.color_enabled = true
  config.include ModelsHelper
  config.include CallbacksHelper

  config.before(:each) do
    NoBrainer.truncate!
  end

  config.after do
  end
end
