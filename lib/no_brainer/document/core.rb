module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  # TODO This assume the primary key is id.
  # RethinkDB can have a custom primary key. careful.
  include ActiveModel::Conversion

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation
  end

  def initialize(attrs={}, options={}); end

  module ClassMethods
    def table_name
      root_class.name.underscore.gsub('/', '__').pluralize
    end

    # Even though we are using class variables, it's threads-safe.
    # It's still racy, but the race is harmless.
    def table
      root_class.class_eval do
        @table ||= RethinkDB::RQL.new.table(table_name).freeze
      end
    end

    # Thread safe because the operation is idempotent
    # (no error if we try to create the table twice)
    def ensure_table!
      root_class.class_eval do
        @table_created ||= !!self.count
      end
    end
  end
end
