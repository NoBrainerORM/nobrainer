module NoBrainer::QueryRunner::TableOnDemand
  def run(env)
    super
  rescue RuntimeError => e
    if e.message =~ /`(FIND|EVAL)_TABLE (.+)`: No entry with that name/
      # TODO Lookup the Model, and get the primary key name
      NoBrainer.table_create $2
      retry
    elsif e.message =~ /`EVAL_DB (.+)`: No entry with that name/
      # arh, we don't have the table name in the error message
      if env[:selection]
        NoBrainer.table_create env[:selection].klass.table_name
        retry
      end
    end
    raise e
  end
end
