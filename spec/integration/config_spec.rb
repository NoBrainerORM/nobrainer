require 'spec_helper'

describe 'config' do
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

    after do
      ENV['RETHINKDB_URL'] = nil
      ENV['RETHINKDB_HOST'] = nil
      ENV['RETHINKDB_PORT'] = nil
      ENV['RETHINKDB_AUTH'] = nil
      ENV['RETHINKDB_USER'] = nil
      ENV['RETHINKDB_PASSWORD'] = nil
      ENV['RETHINKDB_DB'] = nil
    end

    describe "URL settings based on env variables" do
      before { env.each { |k,v| ENV[k] = v } }
      before { NoBrainer::Config.configure { |c| c.reset! } }
      subject { NoBrainer::Config.rethinkdb_urls.first }

      context 'no env (rails settings)' do
        let(:env) { {} }
        it { should == 'rethinkdb://localhost/some_app_env' }
      end

      context 'setting RETHINKDB_URL' do
        let(:env) { { 'RETHINKDB_URL' => 'rethinkdb://l/db' } }
        it { should == 'rethinkdb://l/db' }
      end

      context 'setting RETHINKDB_HOST' do
        let(:env) { { 'RETHINKDB_HOST' => 'host' } }
        it { should == 'rethinkdb://host/some_app_env' }
      end

      context 'setting RETHINKDB_PORT' do
        let(:env) { { 'RETHINKDB_PORT' => '12345' } }
        it { should == 'rethinkdb://localhost:12345/some_app_env' }
      end

      context 'setting RETHINKDB_AUTH' do
        let(:env) { { 'RETHINKDB_AUTH' => 'auth' } }
        it { should == 'rethinkdb://:auth@localhost/some_app_env' }
      end

      context 'setting RETHINKDB_USER and RETHINKDB_PASSWORD' do
        let(:env) { { 'RETHINKDB_USER' => 'user', 'RETHINKDB_PASSWORD' => 'password' } }
        it { should == 'rethinkdb://user:password@localhost/some_app_env' }
      end

      context 'setting RETHINKDB_DB' do
        let(:env) { { 'RETHINKDB_DB' => 'hello' } }
        it { should == 'rethinkdb://localhost/hello' }
      end
    end
  end

  context 'when configuring the app_name and enviroment' do
    it 'sets the rethinkdb_url default' do
      NoBrainer.configure do |c|
        c.reset!
        c.app_name = :app
        c.environment = :test
      end
      NoBrainer::Config.rethinkdb_urls.first.should == 'rethinkdb://localhost/app_test'
    end
  end

  context 'when configuring the environement' do
    it 'sets the the durability appropriatly' do
      NoBrainer.configure do |c|
        c.reset!
        c.app_name = :app
        c.environment = :development
      end
      NoBrainer::Config.run_options[:durability].should == :soft

      NoBrainer.configure do |c|
        c.environment = :test
      end
      NoBrainer::Config.run_options[:durability].should == :soft

      NoBrainer.configure do |c|
        c.environment = :other
      end
      NoBrainer::Config.run_options[:durability].should == :hard
    end
  end

  context 'when configuring bad values' do
    context 'with the url' do
      before { NoBrainer.logger.level = Logger::FATAL }
      it 'yells' do
        expect { NoBrainer.configure { |c| c.rethinkdb_url = 'xxx' }; NoBrainer.run { } }.to raise_error(/Invalid URI/)
        expect { NoBrainer.configure { |c| c.rethinkdb_url = 'blah://xxx/' }; NoBrainer.run { } }.to raise_error(/Invalid URI/)
        expect { NoBrainer.configure { |c| c.rethinkdb_url = 'rethinkdb://x/' }; NoBrainer.run { } }.to raise_error(/No database/)
      end
    end
  end
end
