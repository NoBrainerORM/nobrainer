load './spec/support/_coverage.rb' if ENV['COVERAGE']
require 'rubygems'
require 'bundler'
Bundler.require(:default, ENV['CI'] ? :ci : :development)

SPEC_ROOT = File.expand_path File.dirname(__FILE__)
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require f unless File.basename(f) =~ /^_/ }

database_host = ENV['DB_HOST'] || 'localhost'
db_name       = ENV['DB_NAME'] || 'nobrainer_test'

if ENV['TEST_ENV_NUMBER']
  DB_SUFFIX = "_N#{ENV['TEST_ENV_NUMBER']}"
  db_name = db_name + DB_SUFFIX

  class NoBrainer::QueryRunner::RunOptions < NoBrainer::QueryRunner::Middleware
    class << self
      alias_method :run_with_orig, :run_with
      def run_with(options={}, &block)
        if options[:db]
          options = options.dup
          options[:db] = options[:db] + DB_SUFFIX unless options[:db] =~ /#{DB_SUFFIX}$/
        end
        run_with_orig(options, &block)
      end
    end
  end
end

I18n.enforce_available_locales = true rescue nil

NoBrainer::Document::PrimaryKey.__send__(:remove_const, :DEFAULT_PK_NAME)
NoBrainer::Document::PrimaryKey.__send__(:const_set,    :DEFAULT_PK_NAME, :_id_)

nobrainer_conf = proc do |c|
  c.reset!
  c.rethinkdb_url = "rethinkdb://#{database_host}/#{db_name}"
  c.environment = :test
  c.logger = Logger.new(STDERR).tap { |l| l.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::WARN }
  c.driver = :em if ENV['EM']
end

if ENV['EM']
  require 'fiber'
  class RSpec::Core:: Runner
    alias_method :orig_run_specs, :run_specs

    def run_specs(*args)
      ret = nil
      EventMachine.run do
        Fiber.new do
          ret = orig_run_specs(*args)
          EventMachine.stop
        end.resume
      end
      ret
    end
  end
end

RSpec.configure do |config|
  config.order = :random
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  if ENV['TRACE']
    config.before do
      $trace_file = File.open(ENV['TRACE'], 'w')
      TracePoint.new(:call, :raise) do |tp|
        $trace_file.puts "#{tp.event} #{tp.path} #{tp.method_id}:#{tp.lineno}"
      end.enable
    end
  end

  config.before(:all) do
    NoBrainer.configure(&nobrainer_conf)
    NoBrainer.drop!
  end

  config.before(:each) do
    NoBrainer.configure(&nobrainer_conf)
    NoBrainer.purge!
    NoBrainer::Loader.cleanup
  end
end
