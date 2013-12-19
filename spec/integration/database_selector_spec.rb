require 'spec_helper'

describe 'NoBrainer database selector' do
  before { load_simple_document }
  before do
    NoBrainer.with_database('test_db1') { NoBrainer.drop! }
    NoBrainer.with_database('test_db2') { NoBrainer.drop! }
  end
  after do
    NoBrainer.with_database('test_db1') { NoBrainer.drop! }
    NoBrainer.with_database('test_db2') { NoBrainer.drop! }
  end

  context 'when using the global wrapper' do
    it 'switches databases' do
      NoBrainer.with_database('test_db1') do
        SimpleDocument.create
        SimpleDocument.count.should == 1
      end

      NoBrainer.with_database('test_db2') do
        SimpleDocument.count.should == 0
        2.times { SimpleDocument.create }
        SimpleDocument.count.should == 2

        NoBrainer.with_database('test_db1') do
          SimpleDocument.count.should == 1
        end

        SimpleDocument.count.should == 2
      end

      SimpleDocument.count.should == 0

      NoBrainer.with_database('test_db1') do
        SimpleDocument.count.should == 1
        NoBrainer.drop!
      end

      NoBrainer.with_database('test_db1') do
        SimpleDocument.count.should == 0
      end
    end
  end
end
