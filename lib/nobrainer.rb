require 'set'
require 'active_support'
require 'thread'
%w(module/delegation module/attribute_accessors module/introspection
   class/attribute object/blank object/inclusion object/deep_dup
   object/try hash/keys hash/indifferent_access hash/reverse_merge
   hash/deep_merge array/extract_options)
    .each { |dep| require "active_support/core_ext/#{dep}" }

module NoBrainer
  require 'no_brainer/autoload'
  extend NoBrainer::Autoload

  # We eager load things that could be loaded when handling the first web request.
  # Code that is loaded through the DSL of NoBrainer should not be eager loaded.
  autoload :Document, :IndexManager, :Loader, :Fork, :Geo
  eager_autoload :Config, :Connection, :ConnectionManager,  :Error,
                 :QueryRunner, :Criteria, :RQL

  class << self
    delegate :connection, :disconnect, :to => 'NoBrainer::ConnectionManager'

    delegate :db_create, :db_drop, :db_list,
             :table_create, :table_drop, :table_list,
             :drop!, :purge!, :to => :connection

    delegate :configure, :logger,   :to => 'NoBrainer::Config'
    delegate :run,                  :to => 'NoBrainer::QueryRunner'
    delegate :sync_indexes,         :to => 'NoBrainer::Document::Index::Synchronizer'
    delegate :with, :with_database, :to => 'NoBrainer::QueryRunner::RunOptions'

    def jruby?
      RUBY_PLATFORM == 'java'
    end
  end

  Fork.hook unless jruby?
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/no_brainer/locale/en.yml'
end

require 'no_brainer/railtie' if defined?(Rails)
