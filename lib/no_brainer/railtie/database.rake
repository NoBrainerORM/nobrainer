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

  desc 'Synchronize schema (indexes and table configuration)'
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
  task :migrate => [:sync_schema]
end
