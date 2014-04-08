class NoBrainer::QueryRunner::MissingIndex < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RethinkDB::RqlRuntimeError => e

    index_data = e.message.match /^Index `(?<name>.+)` was not found\.$/
    table_data = e.message.match /table\(\"(?<name>\S+)\"\)/

    if index_data[:name] && table_data[:name]
      raise NoBrainer::Error::MissingIndex.new("Please run \"rake db:update_indexes\" to create the index `#{index_data[:name]}` " +
                                               "in the table `#{table_data[:name]}`\n" +
                                               "--> Read http://nobrainer.io/docs/indexes for more information.")
    end
    raise
  end
end
