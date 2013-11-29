class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    write_query = self.class.is_write_query?(env)
    @runner.call(env).tap do |result|
      # TODO Fix rethinkdb driver: Their classes Term, Query, Response are
      # not scoped to the RethinkDB module! (that would prevent a user from
      # creating a Response model for example).

      if write_query && (result['errors'].to_i != 0 || result['skipped'].to_i != 0)
        raise_write_error(env, result['first_error'])
      end
    end
  rescue RethinkDB::RqlRuntimeError => err
    raise unless write_query
    raise_write_error(env, err.message)
  end

  private

  def self.is_write_query?(env)
    env[:query].body.type.in?([Term::TermType::UPDATE,
                               Term::TermType::DELETE,
                               Term::TermType::REPLACE,
                               Term::TermType::INSERT])
  end

  def raise_write_error(env, error_msg)
    error_msg = self.class.normalize_message(error_msg)
    error_msg += "\nQuery was: #{env[:query].inspect[0..1000]}"
    raise NoBrainer::Error::DocumentNotSaved, error_msg
  end

  def self.normalize_message(message)
    message.to_s.tap do |msg|
      if msg.eql?('')
        return 'Unknown error'
      elsif msg =~ /Expected type OBJECT but found NULL/
        return "Non existent document"
      else
        return msg.split("\nBacktrace").first
      end
    end
  end
end
