require 'rails3_datamapper/setup'
require 'rails3_datamapper/storage'

namespace :db do

  namespace :test do
    task :prepare => ['db:setup']
  end

  task :load_config => :rails_env do
    Rails::DataMapper.configurations = Rails::Application.config.database_configuration
  end

  task :load_models => :environment do
    FileList["app/models/**/*.rb"].each { |model| load model }
  end


  namespace :create do
    desc 'Create all the local databases defined in config/database.yml'
    task :all => :load_config do
      Rails::DataMapper::Storage.create_local_databases
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :create => :load_config do
    Rails::DataMapper::Storage.create_database(Rails::DataMapper.configurations[Rails.env])
    if Rails.env.development? && Rails::DataMapper.configurations['test']
      Rails::DataMapper::Storage.create_database(Rails::DataMapper.configurations['test'])
    end
  end

  namespace :drop do
    desc 'Drop all the local databases defined in config/database.yml'
    task :all => :load_config do
      Rails::DataMapper::Storage.drop_local_databases
    end
  end

  desc "Drops the database for the current Rails.env"
  task :drop => :load_config do
    Rails::DataMapper::Storage.drop_database(Rails::DataMapper.configurations[Rails.env])
  end


  desc 'Perform destructive automigration'
  task :automigrate => :load_models do
    ::DataMapper.auto_migrate!
  end

  desc 'Perform non destructive automigration'
  task :autoupgrade => :load_models do
    ::DataMapper.auto_upgrade!
  end


  namespace :migrate do
    task :load => :environment do
      require 'dm-migrations/migration_runner'
      FileList['db/migrate/*.rb'].each do |migration|
        load migration
      end
    end

    desc 'Migrate up using migrations'
    task :up, :version, :needs => :load do |t, args|
      ::DataMapper::MigrationRunner.migrate_up!(args[:version])
    end

    desc 'Migrate down using migrations'
    task :down, :version, :needs => :load do |t, args|
      ::DataMapper::MigrationRunner.migrate_down!(args[:version])
    end
  end

  desc 'Migrate the database to the latest version'
  task :migrate => 'db:migrate:up'

  namespace :sessions do
    desc "Creates the sessions table for DataMapperStore"
    task :create => :environment do
      require 'rails3_datamapper/session_store'
      Rails::DataMapper::SessionStore::Session.auto_migrate!
      puts "Created '#{Rails::DataMapper.configurations[Rails.env]['database']}.sessions'"
    end

    desc "Clear the sessions table for DataMapperStore"
    task :clear => :environment do
      require 'rails3_datamapper/session_store'
      Rails::DataMapper::SessionStore::Session.all.destroy!
      puts "Deleted entries from '#{Rails::DataMapper.configurations[Rails.env]['database']}.sessions'"
    end
  end

  desc 'Create the database, load the schema, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:automigrate', 'db:seed' ]

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

end
