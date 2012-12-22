module NoBrainer::Base::Core
  extend ActiveSupport::Concern

  # Do not use delegate, as the target is cached.
  def table
    self.class.table
  end

  def table_name
    self.class.table_name
  end

  module ClassMethods
    def table_name
      # XXX Inheritance can make things funny here. Pick the parent.
      self.name.underscore.gsub('/', '__')
    end

    def table
      # XXX Inherence: @ or @@ ?
      @table ||= RethinkDB::RQL.table(table_name)
    end
  end
end
