require 'rethinkdb'
require 'uri'

class NoBrainer::Connection
  attr_accessor :uri

  def initialize(uri)
    self.uri = uri
    parsed_uri # just to raise an exception if there is a problem.
  end

  def parsed_uri
    uri = URI.parse(self.uri)

    if uri.scheme != 'rethinkdb'
      fail NoBrainer::Error::Connection,
           "Invalid URI. Expecting something like " \
           "rethinkdb://host:port/database. Got #{uri}"
    end

    uri_hash(uri).tap do |result|
      fail "No database specified in #{uri}" unless result[:db].present?
    end
  end

  def raw
    @raw ||= RethinkDB::Connection.new(parsed_uri)
  end

  delegate :reconnect, :close, :run, to: :raw
  alias_method :connect, :raw
  alias_method :disconnect, :close

  [:db_create, :db_drop, :db_list, :table_create, :table_drop,
   :table_list].each do |cmd|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{cmd}(*args)
        NoBrainer.run { |r| r.#{cmd}(*args) }
      end
    RUBY
  end

  def drop!
    # XXX Thread.current[:nobrainer_options] is set by
    # NoBrainer::QueryRunner::RunOptions
    db = (Thread.current[:nobrainer_options] || parsed_uri)[:db]
    db_drop(db)['dropped'] == 1
  end

  # Note that truncating each table (purge) is much faster than dropping the
  # database (drop)
  def purge!(options = {})
    table_list.each do |table_name|
      NoBrainer.run { |r| r.table(table_name).delete }
    end
    true
  rescue RuntimeError => e
    raise e unless e.message =~ /No entry with that name/
  end

  private

  def uri_hash(uri)
    {
      auth_key: uri.password,
      host: uri.host,
      port: uri.port || 28_015,
      db: uri.path.gsub(/^\//, '')
    }
  end
end
