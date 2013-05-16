class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env).tap do |result|
      # TODO Fix rethinkdb driver: Their classes Term, Query, Response are
      # not scoped to the RethinkDB module! (that would prevent a user from
      # creating a Response model for example).

      q = env[:query]
      if q.body.type.in?([Term::TermType::UPDATE,
                          Term::TermType::DELETE,
                          Term::TermType::REPLACE,
                          Term::TermType::INSERT])

        if result['errors'].to_i != 0 || result['skipped'].to_i != 0
          error_msg = "Non existant document" if result['skipped'].to_i != 0
          error_msg = "#{result['first_error']}" if result['first_error']
          error_msg += "\nQuery was: #{q.inspect[0..1000]}"
          raise NoBrainer::Error::DocumentNotSaved, error_msg
        end
      end
    end
  end
end
