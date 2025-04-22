# frozen_string_literal: true

require 'spec_helper'

# Nice Rspec seed: 1937
describe 'NoBrainer slow queries feature' do # rubocop:disable RSpec/DescribeClass
  let(:log_slow_queries) { File.join('/tmp', 'rdb_slow.log') }

  before { load_simple_document }

  def run_long_query
    SimpleDocument.first
  end

  context 'when config.on_slow_query is not defined' do
    context "when the slow query log file doesn't exist" do
      before { FileUtils.rm_f(log_slow_queries) && run_long_query }

      it "doesn't not create the log file" do
        expect(File).not_to exist(log_slow_queries)
      end
    end

    context 'when the slow query log file exist' do
      before { File.write(log_slow_queries, "test\n") && run_long_query }

      it "doesn't write to the log file" do
        expect(File.read(log_slow_queries)).to eql("test\n")
      end
    end
  end

  context 'when config.log_slow_queries is defined' do
    before do
      allow(File).to receive(:write)

      allow_any_instance_of(NoBrainer::Profiler::SlowQueries) # rubocop:disable RSpec/AnyInstance
        .to receive(:slow_query?).and_return(true)

      NoBrainer::Config.on_slow_query = lambda do |message|
        File.write(log_slow_queries, message, mode: 'a')
      end

      run_long_query
    end

    it 'does write to the log file' do
      expect(File).to have_received(:write).with(
        log_slow_queries,
        /.*\[\s+[\d.]+ms\] r\.table\("simple_documents"\)\.order_by\(\{"index" => r.asc\(:_id_\)\}\).limit\(1\)/,
        { mode: 'a' }
      )
    end
  end
end
