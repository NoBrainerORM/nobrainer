require 'rethinkdb'
require 'uri'

class NoBrainer::Connection
  attr_accessor :parsed_uri, :orig_uri

  def initialize(uri)
    @orig_uri = uri
    parse_uri(uri)
  end

  def parse_uri(uri)
    @parsed_uri = begin
      uri = URI.parse(uri)

      if uri.scheme != 'rethinkdb'
        raise NoBrainer::Error::Connection,
          "Invalid URI. Expecting something like rethinkdb://host:port/database. Got #{uri}"
      end

      {
        :user     => uri.user,
        :password => uri.password,
        :host     => uri.host,
        :port     => uri.port || 28015,
        :db       => uri.path.gsub(/^\//, ''),
      }.tap { |result| raise "No database specified in #{uri}" unless result[:db].present? }
    end
  end

  def uri
    "rethinkdb://#{'****@' if parsed_uri[:auth_key]}#{parsed_uri[:host]}:#{parsed_uri[:port]}/#{parsed_uri[:db]}"
  end

  def raw
    options = parsed_uri
    options = options.merge(:ssl => NoBrainer::Config.ssl_options) if NoBrainer::Config.ssl_options
    @raw ||= RethinkDB::Connection.new(options).tap { NoBrainer.logger.info("Connected to #{uri}") }
  end

  delegate :reconnect, :close, :run, :to => :raw
  alias_method :connect, :raw
  alias_method :disconnect, :close

  def default_db
    parsed_uri[:db]
  end

  def current_db
    NoBrainer.current_run_options[:db] || default_db
  end
end
