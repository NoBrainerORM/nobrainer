module NoBrainer::Util
  def self.is_write_query?(rql_query)
    rql_type(rql_query) == :write
  end

  def self.rql_type(rql_query)
    case rql_query.body.type
    when Term::TermType::UPDATE,  Term::TermType::DELETE,
         Term::TermType::REPLACE, Term::TermType::INSERT
      :write
    when Term::TermType::DB_CREATE,    Term::TermType::DB_DROP,
         Term::TermType::DB_LIST,      Term::TermType::TABLE_CREATE,
         Term::TermType::TABLE_DROP,   Term::TermType::TABLE_LIST,
         Term::TermType::SYNC,         Term::TermType::INDEX_CREATE,
         Term::TermType::INDEX_DROP,   Term::TermType::INDEX_LIST,
         Term::TermType::INDEX_STATUS, Term::TermType::INDEX_WAIT
      :management
    else
      # XXX Not sure if that's correct, but we'll be happy for logging colors.
      :read
    end
  end
end
