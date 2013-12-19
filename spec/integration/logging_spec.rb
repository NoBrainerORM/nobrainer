require 'spec_helper'

# a simple class that implements the necessary methods for a logger
class TestLogger

  attr_reader :logs

  def initialize
    @logs = []
  end

  def log(severity, message)
    @logs << {severity: severity, message: message}
  end

end

describe 'NoBrainer logging' do
  before { load_simple_document }
  before { NoBrainer.drop! }
  after  { NoBrainer.drop! }

  context 'when using a test logger' do

    before { NoBrainer.logger = TestLogger.new }

    it 'must log insert query' do
      SimpleDocument.create(field1:'foo')
      NoBrainer.logger.logs.count.should > 0 # I'm not sure if we want to hard code the actual number
      NoBrainer.logger.logs.first[:message].index('r.table("simple_documents").insert').should > -1
    end

    it 'must use INFO by default' do
      SimpleDocument.create(field1:'foo')
      NoBrainer.logger.logs.count.should > 0
      NoBrainer.logger.logs.first[:severity] == Logger::INFO
    end

    it 'must use user-defined severity' do
      NoBrainer.log_level = Logger::WARN
      SimpleDocument.create(field1:'foo')
      NoBrainer.logger.logs.count.should > 0
      NoBrainer.logger.logs.first[:severity] == Logger::WARN
    end

  end

end