class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env).tap do |result|
      # TODO Fix rethinkdb driver: Their classes Term, Query, Response are
      # not scoped to the RethinkDB module! (that would prevent a user from
      # creating a Response model for example).

      if is_write_query?(env) && (result['errors'].to_i != 0 || result['skipped'].to_i != 0)
        raise_write_error(env, result['first_error'])
      end
    end
  rescue RethinkDB::RqlRuntimeError => e
    raise unless is_write_query?(env)

    error_msg = e.message.split("\nBacktrace").first
    error_msg = "Non existent document" if e.message =~ /Expected type OBJECT but found NULL/
    raise_write_error(env, error_msg)
  end

  private

  def is_write_query?(env)
    env[:query].body.type.in?([Term::TermType::UPDATE,
                               Term::TermType::DELETE,
                               Term::TermType::REPLACE,
                               Term::TermType::INSERT])
  end

  def raise_write_error(env, error_msg)
    error_msg ||= "Unknown error"
    error_msg += "\nQuery was: #{env[:query].inspect[0..1000]}"
    raise NoBrainer::Error::DocumentNotSaved, error_msg
  end
end
