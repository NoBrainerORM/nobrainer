# frozen_string_literal: true

module NoBrainer
  #
  # The Migrator class is used in order to execute a migration script and store
  # the migration script "version" or timestap in a table allowing to run it
  # only once.
  # The mechanism is heavily inspired by the ActiveRecord one.
  #
  # It supports both migrate and rollback.
  #
  class Migrator
    def self.migrations_table_name
      'nobrainer_migration_versions'
    end

    def initialize(path)
      @path = path
      @version, snake_class_name = path.scan(%r{^.*/(\d+)_(.*)\.rb}).flatten

      @name = snake_class_name ? snake_class_name.camelize : nil
    end

    def migrate
      return if version_exists?

      require @path

      announce 'migrating'

      time = Benchmark.measure do
        migration_script = @name.constantize.new
        migration_script.migrate!
      end

      announce 'migrated (%.4fs)' % time.real

      create_version!
    end

    def rollback
      return unless version_exists?

      announce 'reverting'

      require @path

      time = Benchmark.measure do
        migration_script = @name.constantize.new
        migration_script.rollback!
      end

      announce 'reverted (%.4fs)' % time.real

      remove_version!
    end

    private

    # Stollen from the ActiveRecord gem
    def announce(message)
      text = "#{@version} #{@name}: #{message}"
      length = [0, 75 - text.length].max
      puts "== #{text} #{'=' * length}"
    end

    def check_if_version_exists?
      NoBrainer.run do |r|
        r.table(self.class.migrations_table_name).filter({ version: @version })
      end.first.present?
    end

    def create_migrations_table_if_needed!
      return if migrations_table_exists?

      create_migrations_table!
    end

    def create_migrations_table!
      result = NoBrainer.run do |r|
        r.table_create(self.class.migrations_table_name)
      end

      return if result['tables_created'] == 1

      raise NoBrainer::Error::MigrationFailure,
            'Something prevented from creating the ' \
            "'#{self.class.migrations_table_name}' table."
    end

    def create_version!
      result = NoBrainer.run do |r|
        r.table(self.class.migrations_table_name).insert({ version: @version })
      end

      return true if result['inserted'] == 1

      raise NoBrainer::Error::MigrationFailure,
            "Something prevented from inserting the version '#{@version}'"
    end

    def migrations_table_exists?
      NoBrainer.run(&:table_list).include?(self.class.migrations_table_name)
    end

    def remove_version!
      result = NoBrainer.run do |r|
        r.table(self.class.migrations_table_name)
         .filter({ version: @version })
         .delete
      end

      return true if result['deleted'] == 1

      raise NoBrainer::Error::MigrationFailure,
            "Something prevented from deleting the version '#{@version}'"
    end

    def version_exists?
      create_migrations_table_if_needed!

      check_if_version_exists?
    end
  end
end
