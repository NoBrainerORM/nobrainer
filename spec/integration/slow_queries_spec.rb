# frozen_string_literal: true

require 'spec_helper'

describe 'NoBrainer slow queries feature' do # rubocop:disable RSpec/DescribeClass
  before do
    NoBrainer.configure do |config|
      config.long_query_time = 0.4 # 700ms
      config.slow_query_log_file = File.join('/tmp', 'rdb_slow.log')
    end

    load_simple_document
  end

  def run_long_query
    SimpleDocument.first

    sleep NoBrainer::Config.long_query_time + 0.1 # + 100ms
  end

  context 'when config.log_slow_queries is not `true`' do
    before { NoBrainer::Config.log_slow_queries = false }

    context "when the slow query log file doesn't exist" do
      before do
        FileUtils.rm_f(NoBrainer::Config.slow_query_log_file) && run_long_query
      end

      it "doesn't not create the log file" do
        expect(File.exist?(NoBrainer::Config.slow_query_log_file)).to be_falsy # rubocop:disable RSpec/PredicateMatcher
      end
    end

    context 'when the slow query log file exist' do
      before do
        File.write(NoBrainer::Config.slow_query_log_file, "test\n")
        run_long_query
      end

      it "doesn't write to the log file" do
        expect(File.read(NoBrainer::Config.slow_query_log_file)).to eql("test\n")
      end
    end
  end

  context 'when config.log_slow_queries is `true`' do
    before do
      NoBrainer::Config.log_slow_queries = true
      run_long_query
    end

    it 'does create the log file' do
      expect(File.exist?(NoBrainer::Config.slow_query_log_file)).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    it 'does write to the log file' do
      expect(File.read(NoBrainer::Config.slow_query_log_file)).to match(
        /\[\s+[\d.]+ms\] r\.table\("simple_documents"\)\.order_by\(\{"index" => r.asc\(:_id_\)\}\).limit\(1\)/
      )
    end
  end
end
