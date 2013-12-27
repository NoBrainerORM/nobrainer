class NoBrainer::QueryRunner::TableOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if NoBrainer::Config.auto_create_tables &&
       e.message =~ /^Table `(.+)` does not exist\.$/
      auto_create_table(env, $1)
      retry
    end
    raise
  end

  private

  def auto_create_table(env, table_name)
    if env[:auto_create_table] == table_name
      raise "Auto table creation is not working with #{table_name}"
    end
    env[:auto_create_table] = table_name

    # FIXME This stinks.
    database_names = find_db_names(env[:query])
    case database_names.size
    when 0 then NoBrainer.table_create(table_name)
    when 1 then NoBrainer.with_database(database_names.first) { NoBrainer.table_create(table_name) }
    else raise "Ambiguous database name for creation on demand: #{database_names}"
    end
  rescue RuntimeError => e
    # We might have raced with another table create
    raise unless e.message =~ /Table `#{table_name}` already exists/
  end

  def find_db_names(terms)
    terms = terms.body.args if terms.is_a?(RethinkDB::RQL)
    terms.map do |term|
      next unless term.is_a?(Term)
      if term.type == Term::TermType::DB
        term.args.first.datum.r_str
      else
        find_db_names(term.args)
      end
    end.flatten.uniq
  end
end
