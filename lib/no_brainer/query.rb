module NoBrainer::Query
  def self.run(options={}, &block)
    NoBrainer.connection.run(options, &block)
  rescue RuntimeError => e
    if e.message =~ /`FIND_TABLE (.+)`: No entry with that name/
      # TODO Lookup the Model, and get the options for the primary key
      NoBrainer.table_create $1
      retry
    elsif e.message =~ /`FIND_DB (.+)`: No entry with that name/
      NoBrainer.db_create $1
      retry
    else
      raise e
    end
  end
end
