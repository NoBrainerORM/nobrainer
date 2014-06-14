class NoBrainer::QueryRunner::MissingIndex < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RethinkDB::RqlRuntimeError => e
    if e.message =~ /^Index `(.+)` was not found on table `(.+)\.(.+)`\.$/
      index_name = $1
      database_name = $2
      table_name = $3

      klass = NoBrainer::Document.all.select { |m| m.table_name == table_name }.first
      if klass && klass.pk_name.to_s == index_name
        err_msg  = "Please run update the primary key `#{index_name}` in the table `#{database_name}.#{table_name}`."
      else
        err_msg  = "Please run \"rake db:update_indexes\" to create the index `#{index_name}`"
        err_msg += " in the table `#{database_name}.#{table_name}`."
        err_msg += "\n--> Read http://nobrainer.io/docs/indexes for more information."
      end

      raise NoBrainer::Error::MissingIndex.new(err_msg)
    end
    raise
  end
end
