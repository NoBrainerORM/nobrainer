class NoBrainer::Database
  attr_accessor :connection

  delegate :database_name, :to => :connection

  def initialize(connection)
    self.connection = connection
  end

  def raw
    @raw ||= RethinkDB::RQL.new.db(database_name)
  end

  def drop!
    connection.db_drop(database_name)
  end

  # Note that truncating each table (purge) is much faster than dropping the
  # database (drop)
  def purge!(options={})
    table_list.each do |table_name|
      self.class.truncate_table!(table_name)
    end
  rescue RuntimeError => e
    raise e unless e.message =~ /No entry with that name/
  end

  [:table_create, :table_drop, :table_list].each do |cmd|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{cmd}(*args)
        NoBrainer.run { raw.#{cmd}(*args) }
      end
    RUBY
  end

  def self.truncate_table!(table_name)
    NoBrainer.run { RethinkDB::RQL.new.table(table_name).delete }
  end
end
