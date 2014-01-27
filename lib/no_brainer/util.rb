module NoBrainer::Util
  WRITE_TYPES = [
    Term::TermType::UPDATE,  Term::TermType::DELETE,
    Term::TermType::REPLACE, Term::TermType::INSERT
  ]
  MANAGEMENT_TYPES = [
    Term::TermType::DB_CREATE,    Term::TermType::DB_DROP,
    Term::TermType::DB_LIST,      Term::TermType::TABLE_CREATE,
    Term::TermType::TABLE_DROP,   Term::TermType::TABLE_LIST,
    Term::TermType::SYNC,         Term::TermType::INDEX_CREATE,
    Term::TermType::INDEX_DROP,   Term::TermType::INDEX_LIST,
    Term::TermType::INDEX_STATUS, Term::TermType::INDEX_WAIT
  ]

  def self.write_query?(rql_query)
    rql_type(rql_query) == :write
  end

  def self.rql_type(rql_query)
    type = rql_query.body.type

    return :write if type.in? WRITE_TYPES
    return :management if type.in? MANAGEMENT_TYPES

    # XXX Not sure if that's correct, but we'll be happy for logging colors.
    :read
  end
end
