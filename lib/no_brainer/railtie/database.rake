# frozen_string_literal: true

def sorted_migration_script_pathes
  Dir.glob(Rails.root.join('db', 'migrate', '*.rb')).sort
end

namespace :nobrainer do
  desc 'Drop the database'
  task :drop => :environment do
    NoBrainer.drop!
  end

  desc 'Rebalance all tables'
  task :rebalance => :environment do
    NoBrainer.rebalance(:verbose => true)
  end

  task :sync_indexes => :environment do
    NoBrainer.sync_indexes(:verbose => true)
  end

  task :sync_table_config => :environment do
    NoBrainer.sync_table_config(:verbose => true)
  end

  desc 'Synchronize schema'
  task :sync_schema => :environment do
    NoBrainer.sync_schema(:verbose => true)
  end

  task :sync_schema_quiet => :environment do
    NoBrainer.sync_schema
  end

  desc 'Load seed data from db/seeds.rb'
  task :seed => :environment do
    Rails.application.load_seed
  end

  task :setup => [:sync_schema_quiet, :seed]

  desc 'Equivalent to :drop + :sync_schema + :seed'
  task :reset => [:drop, :sync_schema_quiet, :seed]

  task :create => [:sync_schema]

  desc 'Run migration scripts'
  task :migrate => :environment do
    NoBrainer.sync_schema

    sorted_migration_script_pathes.each do |script|
      migrator = NoBrainer::Migrator.new(script)
      migrator.migrate
    end
  end

  desc 'Rollback the last migration script'
  task :rollback => :environment do
    sorted_migration_script_pathes.reverse.each do |script|
      migrator = NoBrainer::Migrator.new(script)
      break if migrator.rollback
    end
  end
end
