class NoBrainer::Connection
  # A connection is bound to a specific database.

  attr_accessor :uri, :host, :port, :database_name

  def initialize(uri)
    self.uri = uri
    parse_uri
  end

  def raw
    @raw ||= RethinkDB::Connection.new(:host => host, :port => port, :db => database_name)
  end

  alias_method :connect, :raw
  delegate :reconnect, :close, :run, :to => :raw

  [:db_create, :db_drop, :db_list].each do |cmd|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{cmd}(*args)
        NoBrainer.run { RethinkDB::RQL.new.#{cmd}(*args) }
      end
    RUBY
  end

  def database
    @database ||= NoBrainer::Database.new(self)
  end

  private

  def parse_uri
    require 'uri'
    parsed_uri = URI.parse(uri)

    if parsed_uri.scheme != 'rethinkdb'
      raise NoBrainer::Error::Connection,
        "Invalid URI. Expecting something like rethinkdb://host:port/database. Got #{uri}"
    end

    self.host = parsed_uri.host
    self.port = parsed_uri.port || 28015
    self.database_name = parsed_uri.path.gsub(/^\//, '')
  end
end
