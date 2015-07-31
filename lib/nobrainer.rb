require 'set'
require 'active_support'
require 'active_model'
require 'thread'
%w(module/delegation module/attribute_accessors module/introspection
   class/attribute object/blank object/inclusion object/deep_dup
   object/try hash/keys hash/indifferent_access hash/reverse_merge
   hash/deep_merge hash/slice array/extract_options)
    .each { |dep| require "active_support/core_ext/#{dep}" }

module NoBrainer
  require 'no_brainer/autoload'
  extend NoBrainer::Autoload

  # We eager load things that could be loaded when handling the first web request.
  # Code that is loaded through the DSL of NoBrainer should not be eager loaded.
  autoload :Document, :IndexManager, :Loader, :Fork, :Geo, :SymbolDecoration
  eager_autoload :Config, :Connection, :ConnectionManager, :Error,
                 :QueryRunner, :Criteria, :RQL, :Lock, :Profiler, :System

  class << self
    delegate :connection, :disconnect, :to => 'NoBrainer::ConnectionManager'

    delegate :drop!, :purge!, :default_db, :current_db, :to => :connection

    delegate :configure, :logger,             :to => 'NoBrainer::Config'
    delegate :run,                            :to => 'NoBrainer::QueryRunner'
    delegate :current_run_options, :run_with, :to => 'NoBrainer::QueryRunner::RunOptions'

    delegate :with, :with_database, :to => 'NoBrainer::QueryRunner::RunOptions' # deprecated

    delegate :sync_indexes, :sync_table_config, :sync_schema, :rebalance, :to => 'NoBrainer::Document::TableConfig'

    delegate :eager_load, :to => 'NoBrainer::Document::Association::EagerLoader'

    def jruby?
      RUBY_PLATFORM == 'java'
    end
  end

  Fork.hook unless jruby?
  SymbolDecoration.hook
end

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.dirname(__FILE__) + '/no_brainer/locale/en.yml'
end

require 'no_brainer/railtie' if defined?(Rails)
