require 'spec_helper'

describe 'NoBrainer logging' do
  before { load_simple_document }
  before do
    define_class :TestLogger do
      attr_reader :logs

      def initialize
        @logs = []
      end

      def add(level, message)
        @logs << message
      end

      %w(fatal error warn info debug).each do |level|
        define_method(level) do |message|
          add(level, message)
        end
      end

      def level
        Logger::DEBUG
      end
    end
  end

  context 'when using a logger' do
    let(:logger) { TestLogger.new }
    before { NoBrainer.configure { |config| config.logger = logger } }

    it 'must log insert query' do
      2.times { SimpleDocument.create(field1:'foo') }
      msg = logger.logs.select { |l| l['r.table("simple_documents").insert'] }.first
      msg.should_not =~ /\n/
      msg.should_not be_nil
    end
  end
end
