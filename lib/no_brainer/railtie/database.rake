namespace :db do
  desc 'Drop the database'
  task :drop => :environment do
    NoBrainer.drop!
  end

  desc 'Load seed data from db/seeds.rb'
  task :seed => :environment do
    Rails.application.load_seed
  end

  desc 'Create and drop indexes on the database'
  task :update_indexes => :environment do
    NoBrainer.update_indexes(:verbose => true)
  end

  task :update_indexes_quiet => :environment do
    NoBrainer.update_indexes
  end

  desc 'Equivalent to db:update_indexes + db:seed'
  task :setup => [ :update_indexes_quiet, :seed ]

  desc 'Equivalent to db:drop + db:setup'
  task :reset => [ :drop, :setup ]

  task :create => :environment do
    # noop
  end

  task :migrate => :environment do
    # noop
  end
end
