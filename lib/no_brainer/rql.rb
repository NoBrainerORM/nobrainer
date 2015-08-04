module NoBrainer::RQL
  include RethinkDB::Term::TermType
  extend self

  def reset_lambda_var_counter
    RethinkDB::RQL.class_variable_set(:@@gensym_cnt, 0)
  end

  def rql_proc_as_json(block)
    reset_lambda_var_counter
    RethinkDB::Shim.load_json(
      RethinkDB::Shim.dump_json(
        RethinkDB::RQL.new.new_func(&block)))
  end

  def is_write_query?(rql)
    type_of(rql) == :write
  end

  def get_rql_statement(rql)
    rql.is_a?(RethinkDB::RQL) && rql.body.is_a?(Array) && rql.body.first
  end

  def db_drop?(rql)
    get_rql_statement(rql) == DB_DROP
  end

  def type_of(rql)
    case get_rql_statement(rql)
    when UPDATE, DELETE, REPLACE, INSERT
      :write
    when DB_CREATE, DB_DROP, DB_LIST, TABLE_CREATE, TABLE_DROP, TABLE_LIST,
         INDEX_CREATE, INDEX_DROP, INDEX_LIST, INDEX_STATUS, INDEX_WAIT, INDEX_RENAME,
         CONFIG, STATUS, WAIT, RECONFIGURE, REBALANCE, SYNC
      :management
    else
      # XXX Not necessarily correct, but we'll be happy for logging colors.
      :read
    end
  end
end
