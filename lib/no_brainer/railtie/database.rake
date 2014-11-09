namespace :nobrainer do
  desc 'Drop the database'
  task :drop => :environment do
    NoBrainer.drop!
  end

  desc 'Synchronize index definitions'
  task :sync_indexes => :environment do
    NoBrainer.sync_indexes(:verbose => true)
  end

  task :sync_indexes_quiet => :environment do
    NoBrainer.sync_indexes
  end

  desc 'Load seed data from db/seeds.rb'
  task :seed => :environment do
    Rails.application.load_seed
  end

  desc 'Equivalent to :sync_indexes_quiet + :seed'
  task :setup => [:sync_indexes_quiet, :seed]

  desc 'Equivalent to :drop + :setup'
  task :reset => [:drop, :setup]

  task :create => :environment do
    # noop
  end

  task :migrate => :environment do
    # noop
  end
end
