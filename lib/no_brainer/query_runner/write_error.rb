class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    write_query = NoBrainer::RQL.is_write_query?(env[:query])
    @runner.call(env).tap do |result|
      if write_query && (result['errors'].to_i != 0)
        error_msg = result['first_error']
        raise_write_error(env, error_msg)
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
    raise NoBrainer::Error::DocumentNotPersisted, error_msg
  end
end
