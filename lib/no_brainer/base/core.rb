module NoBrainer::Base::Core
  extend ActiveSupport::Concern

  def initialize(attrs={}, options={})
    clear_internal_cache
  end

  def clear_internal_cache
  end

  def ==(other)
    return super unless self.class == other.class
    return false if self.id.nil?
    # TODO FIXME Should we check the attributes?
    self.id == other.id
  end

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

    # Even though we are using class variables,
    # these guys are thread-safe.
    # It's still racy, but the race is harmless.
    def table
      @table ||= RethinkDB::RQL.table(table_name)
    end

    def ensure_table!
      self.count unless @table_created
      @table_created = true
    end
  end
end
