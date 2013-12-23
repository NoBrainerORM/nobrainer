require 'spec_helper'

# a simple class that implements the necessary methods for a logger
class TestLogger

  attr_reader :logs

  def initialize
    @logs = []
  end

  def debug(message)
    @logs << message
  end

end

describe 'NoBrainer logging' do
  before { load_simple_document }
  before { NoBrainer.drop! }
  after  { NoBrainer.drop! }

  context 'when using a test logger' do

    before do
      NoBrainer.configure do |config|
        config.logger = TestLogger.new
      end
    end

    it 'must log insert query' do
      SimpleDocument.create(field1:'foo')
      NoBrainer.logger.logs.count.should > 0 # I'm not sure if we want to hard code the actual number
      NoBrainer.logger.logs.first.index('r.table("simple_documents").insert').should > -1
    end

  end

end