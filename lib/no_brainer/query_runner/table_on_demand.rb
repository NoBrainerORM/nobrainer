module NoBrainer::QueryRunner::TableOnDemand
  def run(env)
    super
  rescue RuntimeError => e
    if e.message =~ /`FIND_TABLE (.+)`: No entry with that name/
      # TODO Lookup the Model, and get the options for the primary key
      NoBrainer.table_create $1
      retry
    end
    raise e
  end
end
