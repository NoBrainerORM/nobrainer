require 'spec_helper'

describe 'config' do
  after do
    ENV['RETHINKDB_URL'] = nil
    ENV['RETHINKDB_HOST'] = nil
    ENV['RETHINKDB_PORT'] = nil
    ENV['RETHINKDB_AUTH'] = nil
  end

  before do
    define_constant :SomeApp do
    end

    define_constant :'SomeApp::Application' do
    end

    define_constant :Rails do
      def self.application
        SomeApp::Application.new
      end

      def self.env
        'env'
      end
    end
  end

  it 'picks a url default' do
    ENV['RETHINKDB_URL'] = 'rethink_url'
    NoBrainer::Config.default_rethinkdb_url.should == 'rethink_url'
    ENV['RETHINKDB_URL'] = nil
    NoBrainer::Config.default_rethinkdb_url.should == 'rethinkdb://localhost/some_app_env'
    ENV['RETHINKDB_HOST'] = 'host'
    NoBrainer::Config.default_rethinkdb_url.should == 'rethinkdb://host/some_app_env'
    ENV['RETHINKDB_PORT'] = '12345'
    NoBrainer::Config.default_rethinkdb_url.should == 'rethinkdb://host:12345/some_app_env'
    ENV['RETHINKDB_AUTH'] = 'auth'
    NoBrainer::Config.default_rethinkdb_url.should == 'rethinkdb://:auth@host:12345/some_app_env'
  end
end
