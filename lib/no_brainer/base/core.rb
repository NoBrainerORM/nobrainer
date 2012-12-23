module NoBrainer::Base::Core
  extend ActiveSupport::Concern

  def table
    self.class.table
  end

  def table_name
    self.class.table_name
  end

  module ClassMethods
    def table_name
      # TODO FIXME Inheritance can make things funny here. Pick the parent.
      self.name.underscore.gsub('/', '__')
    end

    def table
      # TODO FIXME Inherence: @ or @@ ?
      @table ||= RethinkDB::RQL.table(table_name)
    end

    def ensure_table!
      # this will trigger a table creation if needed
      # TODO FIXME @ or @@ ?
      self.count unless @table_created
      @table_created = true
    end
  end
end
