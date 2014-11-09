module NoBrainer::RQL
  include RethinkDB::Term::TermType
  extend self

  def reset_lambda_var_counter
    RethinkDB::RQL.class_variable_set(:@@gensym_cnt, 0)
  end

  def rql_proc_as_json(block)
    reset_lambda_var_counter
    RethinkDB::RQL.new.new_func(&block).as_json
  end

  def is_write_query?(rql_query)
    type_of(rql_query) == :write
  end

  def type_of(rql_query)
    case rql_query.body.first
    when UPDATE, DELETE, REPLACE, INSERT
      :write
    when DB_CREATE, DB_DROP, DB_LIST, TABLE_CREATE, TABLE_DROP, TABLE_LIST, SYNC,
         INDEX_CREATE, INDEX_DROP, INDEX_LIST, INDEX_STATUS, INDEX_WAIT
      :management
    else
      # XXX Not sure if that's correct, but we'll be happy for logging colors.
      :read
    end
  end

  def is_table?(rql)
    rql.body.first == TABLE
  end
end
