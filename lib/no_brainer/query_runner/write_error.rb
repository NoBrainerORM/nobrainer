class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    write_query = NoBrainer::Util.is_write_query?(env[:query])
    @runner.call(env).tap do |result|
      # TODO Fix rethinkdb driver: Their classes Term, Query, Response are
      # not scoped to the RethinkDB module! (that would prevent a user from
      # creating a Response model for example).

      if write_query && (result['errors'].to_i != 0 || result['skipped'].to_i != 0)
        raise_write_error(env, result['first_error'])
      end
    end
  rescue RethinkDB::RqlRuntimeError => e
    raise unless write_query

    error_msg = e.message.split("\nBacktrace").first
    error_msg = "Non existent document" if e.message =~ /Expected type OBJECT but found NULL/
    raise_write_error(env, error_msg)
  end

  private

  def raise_write_error(env, error_msg)
    error_msg ||= "Unknown error"
    error_msg += "\nQuery was: #{env[:query].inspect[0..1000]}"
    raise NoBrainer::Error::DocumentNotSaved, error_msg
  end
end
