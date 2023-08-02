# frozen_string_literal: true

require 'spec_helper'

describe 'NoBrainer slow queries feature' do # rubocop:disable RSpec/DescribeClass
  def log_slow_queries
    File.join('/tmp', 'rdb_slow.log')
  end

  before do
    NoBrainer::Config.long_query_time = 0.4 # 700ms

    load_simple_document
  end

  def run_long_query
    SimpleDocument.first

    sleep NoBrainer::Config.long_query_time + 0.1 # + 100ms
  end

  context 'when config.on_slow_query is not defined' do
    context "when the slow query log file doesn't exist" do
      before do
        FileUtils.rm_f(log_slow_queries) && run_long_query
      end

      it "doesn't not create the log file" do
        expect(File.exist?(log_slow_queries)).to be_falsy # rubocop:disable RSpec/PredicateMatcher
      end
    end

    context 'when the slow query log file exist' do
      before do
        File.write(log_slow_queries, "test\n")
        run_long_query
      end

      it "doesn't write to the log file" do
        expect(File.read(log_slow_queries)).to eql("test\n")
      end
    end
  end

  context 'when config.log_slow_queries is defined' do
    before do
      NoBrainer::Config.on_slow_query = lambda do |message|
        # Write the log message to /var/log/rethinkdb/slow_queries.log file
        File.write(
          log_slow_queries,
          message,
          mode: 'a'
        )
      end

      run_long_query
    end

    it 'does create the log file' do
      expect(File.exist?(log_slow_queries)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    it 'does write to the log file' do
      expect(File.read(log_slow_queries)).to match(
        /\[\s+[\d.]+ms\] r\.table\("simple_documents"\)\.order_by\(\{"index" => r.asc\(:_id_\)\}\).limit\(1\)/
      )
    end
  end
end
