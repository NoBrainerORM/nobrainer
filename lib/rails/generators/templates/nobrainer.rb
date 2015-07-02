NoBrainer.configure do |config|
  # app_name is the name of your application in lowercase.
  # When using Rails, the application name is automatically inferred.
  # config.app_name = config.default_app_name

  # environment defaults to Rails.env for Rails apps or to the environment
  # variables RUBY_ENV, RAILS_ENV, RACK_ENV, or :production.
  # config.environment = config.default_environment

  # The rethinkdb_url specifies the RethinkDB database connection url.
  # When left unspecified, NoBrainer picks a database connection by default.
  # The default is to use localhost, with a database name matching the
  # application name and the environment.
  # NoBrainer also reads environment variables when defined:
  # * RETHINKDB_URL, RDB_URL
  # * RETHINKDB_HOST, RETHINKDB_PORT, RETHINKDB_DB, RETHINKDB_AUTH
  # * RDB_HOST, RDB_PORT, RDB_DB, RDB_AUTH
  # config.rethinkdb_url = config.default_rethinkdb_url

  # NoBrainer uses logger to emit debugging information.
  # The default logger is the Rails logger if run with Rails,
  # otherwise Logger.new(STDERR) with a WARN level.
  # If the logger is configured with a DEBUG level,
  # then each database query is emitted.
  # config.logger = config.default_logger

  # NoBrainer will colorize the queries if colorize_logger is true.
  # Specifically, NoBrainer will colorize management RQL queries in yellow,
  # write queries in red and read queries in green.
  # config.colorize_logger = true

  # You probably do not want to use both NoBrainer and ActiveRecord in your
  # application. NoBrainer will emit a warning if you do so.
  # You can turn off the warning if you want to use both.
  # config.warn_on_active_record = true

  # When the network connection is lost, NoBrainer can retry running a given
  # query a few times before giving up. Note that this can be a problem with
  # non idempotent write queries such as increments.
  # Setting it to 0 disable retries during reconnections.
  # The default is 1 for development or test environment, otherwise 15.
  # config.max_retries_on_connection_failure = \
  #   config.default_max_retries_on_connection_failure

  # Configures the durability for database writes.
  # The default is :soft for development or test environment, otherwise :hard.
  # config.durability = config.default_durability

  # Persisted Strings have a configurable maximum length. To get rid of the
  # length validation, you may use the Text type instead.
  # config.max_string_length = 255

  # user_timezone can be configured with :utc, :local, or :unchanged.
  # When reading an attribute from a model which type is Time, the timezone
  # of that time is translated according to this setting.
  # config.user_timezone = :local

  # db_timezone can be configured with :utc, :local, or :unchanged.
  # When writting to the database, the timezone of Time attributes are
  # translated according to this setting.
  # config.db_timezone = :utc

  # Default options used when compiling geo queries.
  # config.geo_options => { :geo_system => 'WGS84', :unit => 'm' }

  # Configures which mechanism to use in order to perform non-racy uniqueness
  # validations. More about this behavior in the Distributed Locks section.
  # config.distributed_lock_class = "NoBrainer::Lock"

  # Configures the default timing lock options.
  # config.lock_options = { :expire => 60, :timeout => 10 }

  # Instead of using a single connection to the database, You can tell
  # NoBrainer to spin up a new connection for each thread. This is
  # useful for multi-threading usage such as Sidekiq.
  # Call NoBrainer.disconnect before a thread exits, otherwise you will have
  # a resource leak, and you will run out of connections.
  # Note that this is solution is temporary, until we get a connection pool.
  # config.per_thread_connection = false

  # The machine id is used to generate primary keys. The default one is seeded
  # with the machine IP with Socket.gethostname.
  # The env variable MACHINE_ID can also be used to set the machine id.
  # When using distinct machine_id, then primary keys are guaranteed to be
  # generated without conflicts.
  # config.machine_id = config.default_machine_id

  # Criteria cache elements. For example, the result of a has_many association
  # is cached. The per criteria cache is disabled if it grows too big to avoid
  # out of memory issues.
  # config.criteria_cache_max_entries = 10_000
end
