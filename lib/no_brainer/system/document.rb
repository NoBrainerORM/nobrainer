module NoBrainer::System::Document
  extend ActiveSupport::Concern

  include NoBrainer::Document
  include NoBrainer::Document::DynamicAttributes

  included do
    disable_perf_warnings

    field :id, :type => Object, :default => nil, :primary_key => true

    default_scope { without_ordering }
  end

  module ClassMethods
    def table_name
      table_config_options[:name] || name.split('::').last.underscore
    end

    def rql_table
      RethinkDB::RQL.new.db('rethinkdb').table(table_name)
    end
  end
end
