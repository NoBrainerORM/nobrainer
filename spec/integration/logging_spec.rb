require 'spec_helper'

describe 'NoBrainer logging' do
  before { load_simple_document }
  before do
    define_constant :TestLogger do
      attr_reader :logs

      def initialize
        @logs = []
      end

      def debug(message)
        @logs << message
      end

      def level
        Logger::DEBUG
      end
    end
  end

  context 'when using a test logger' do
    before do
      NoBrainer.configure do |config|
        config.logger = TestLogger.new
      end
    end

    it 'must log insert query' do
      SimpleDocument.create(field1:'foo')
      NoBrainer.logger.logs.first.index('r.table("simple_documents").insert').should > -1
    end
  end
end
