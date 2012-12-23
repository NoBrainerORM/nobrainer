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
      # TODO find a better solution
      # Note: that's what happen when we do a count() on a table
      # that doesn't exist.
      q = env[:query]
      case q.body[0]
      when :call
        selection = q.body[2][0].body
        raise 'oops' if selection[0] != :table
        NoBrainer.table_create selection[2]
        retry
      end
    end
    raise e
  end
end
