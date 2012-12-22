module NoBrainer::Query
  def self.run(options={}, &block)
    db_find_retries = 0
    begin
      NoBrainer.connection.run(options, &block)
    rescue RuntimeError => e
      if e.message =~ /`FIND_TABLE (.+)`: No entry with that name/
        # TODO Lookup the Model, and get the options for the primary key
        NoBrainer.table_create $1
        retry
      elsif e.message =~ /`FIND_DB (.+)`: No entry with that name/
        # RethinkDB may return an FIND_DB not found immediately
        # after having created the new database, Be patient.
        NoBrainer.db_create $1 if db_find_retries == 0
        retry if (db_find_retries += 1) < 10
      else
        raise e
      end
    end
  end
end
