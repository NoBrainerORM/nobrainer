class NoBrainer::QueryRunner::MissingIndex < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RethinkDB::RqlRuntimeError => e
    if e.message =~ /^Index `(.+)` was not found\.$/
      index_name = $1
      table_name = find_table_names(env[:query])

      err_msg  = "Please run \"rake db:update_indexes\" to create the index `#{index_name}`"
      err_msg += " in the table #{table_name.map { |t| "`#{t}`"}.join(", ")}." if table_name.present?
      err_msg += "\n--> Read http://nobrainer.io/docs/indexes for more information."

      raise NoBrainer::Error::MissingIndex.new(err_msg)
    end
    raise
  end

  private

  def find_table_names(terms)
    terms = terms.body.args if terms.is_a?(RethinkDB::RQL)
    terms.map do |term|
      next unless term.is_a?(Term)
      if term.type == Term::TermType::TABLE
        term.args.first.datum.r_str
      else
        find_table_names(term.args)
      end
    end.flatten.uniq
  end
end
