class NoBrainer::QueryRunner::MissingIndex < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RethinkDB::RqlRuntimeError => e
    if e.message =~ /^Index `(.+)` was not found\.$/
      raise NoBrainer::Error::MissingIndex.new("Please run \"rake db:update_indexes\" to create the index `#{$1}`\n" +
                                               "--> Read http://nobrainer.io/docs/indexes for more information.")
    end
    raise
  end
end
