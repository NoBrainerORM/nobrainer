namespace :db do
  desc 'Drop the database'
  task :drop => :environment do
    NoBrainer.drop!
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    Rails.application.load_seed
  end

  desc 'Equivalent to db:seed'
  task :setup => [ 'db:seed' ]

  desc 'Equivalent to db:drop + db:seed'
  task :reset => [ 'db:drop', 'db:seed' ]

  task :create => :environment do
    # noop
  end

  task :migrate => :environment do
    # noop
  end

  desc 'Update indexes'
  task :update_indexes => :environment do
    NoBrainer.update_indexes(:verbose => true)
  end
end
