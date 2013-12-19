class NoBrainer::QueryRunner::TableOnDemand < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if e.message =~ /^Table `(.+)` does not exist\.$/

      # FIXME This stinks.
      database_names = find_db_names(env[:query])
      case database_names.size
      when 0 then NoBrainer.table_create $1
      when 1 then NoBrainer.with_database(database_names.first) { NoBrainer.table_create $1 }
      else raise "Ambiguous database name for creation on demand: #{database_names}"
      end

      retry
    end
    raise e
  end

  private

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
