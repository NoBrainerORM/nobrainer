class NoBrainer::QueryRunner::WriteError < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env).tap do |result|
      q = env[:query]
      if q.is_a? RethinkDB::Write_Query
        expected = 1
        case q.body[0]
        when :insert      then field = 'inserted'; expected = q.body[2].count
        when :pointdelete then field = 'deleted'
        when :pointupdate then field = 'updated'
        end

        got = result[field]
        if got && expected != got
          error_msg = "#{got} documents were #{field}, but expected #{expected}"
          if result['first_error']
            # FIXME The driver injects a piece of backtrace, which is useless.
            error_msg += "\n#{result['first_error']}"
          else
            error_msg += "\nQuery was: #{q.inspect[0..1000]}"
          end
          raise NoBrainer::Error::DocumentNotSaved, error_msg
        end
      end
    end
  end
end
