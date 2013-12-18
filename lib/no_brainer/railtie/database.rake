namespace :db do
  unless Rake::Task.task_defined?("db:drop")
    desc 'Truncate all the tables'
    task :drop => :environment do
      NoBrainer.purge! :drop => true
    end
  end

  unless Rake::Task.task_defined?("db:seed")
    desc 'Load the seed data from db/seeds.rb'
    task :seed => :environment do
      Rails.application.load_seed
    end
  end

  unless Rake::Task.task_defined?("db:setup")
    desc 'Equivalent to db:seed'
    task :setup => [ 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:reset")
    desc 'Equivalent to db:drop + db:seed'
    task :reset => [ 'db:drop', 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:create")
    task :create => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:migrate")
    task :migrate => :environment do
      # noop
    end
  end

  unless Rake::Task.task_defined?("db:update_indexes")
    desc 'Update indexes'
    task :update_indexes => :environment do
      NoBrainer.update_indexes(:verbose => true)
    end
  end
end
