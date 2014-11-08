require 'spec_helper'

describe 'config' do
  after do
    ENV['RETHINKDB_URL'] = nil
    ENV['RETHINKDB_HOST'] = nil
    ENV['RETHINKDB_PORT'] = nil
    ENV['RETHINKDB_AUTH'] = nil
    ENV['RETHINKDB_DB'] = nil
  end

  context 'with a rails app' do
    before do
      define_class :SomeApp do
      end

      define_class :'SomeApp::Application' do
      end

      define_class :Rails do
        def self.application
          SomeApp::Application.new
        end

        def self.env
          'env'
        end
      end
    end

    it 'picks a default url' do
      ENV['RETHINKDB_URL'] = 'rethink_url'
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethink_url'

      ENV['RETHINKDB_URL'] = nil
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethinkdb://localhost/some_app_env'

      ENV['RETHINKDB_HOST'] = 'host'
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethinkdb://host/some_app_env'

      ENV['RETHINKDB_PORT'] = '12345'
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethinkdb://host:12345/some_app_env'

      ENV['RETHINKDB_AUTH'] = 'auth'
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethinkdb://:auth@host:12345/some_app_env'

      ENV['RETHINKDB_DB'] = 'hello'
      NoBrainer::Config.reset!
      NoBrainer::Config.rethinkdb_url.should == 'rethinkdb://:auth@host:12345/hello'
    end
  end
end
