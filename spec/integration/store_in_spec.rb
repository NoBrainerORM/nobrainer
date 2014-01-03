require 'spec_helper'

describe 'NoBrainer store_in' do
  before { load_simple_document }
  before do
    NoBrainer.drop!
    NoBrainer.with_database('test_db1') { NoBrainer.drop! }
    NoBrainer.with_database('test_db2') { NoBrainer.drop! }
  end
  after do
    NoBrainer.drop!
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

  context 'when using store_in to switch databases' do
    before do
      SimpleDocument.store_in :database => ->{ @database }
    end

    it 'switches databases' do
      @database = 'test_db1'
      SimpleDocument.create
      SimpleDocument.count.should == 1

      @database = 'test_db2'
      SimpleDocument.count.should == 0
      2.times { SimpleDocument.create }
      SimpleDocument.count.should == 2

      @database = 'test_db1'
      SimpleDocument.count.should == 1
    end
  end

  context 'when using store_in to switch tables' do
    before do
      SimpleDocument.store_in :table => ->{ @table }
    end

    it 'switches databases' do
      @table = 'table1'
      SimpleDocument.create
      SimpleDocument.count.should == 1

      @table = 'table2'
      SimpleDocument.count.should == 0
      2.times { SimpleDocument.create }
      SimpleDocument.count.should == 2

      @table = 'table1'
      SimpleDocument.count.should == 1

      NoBrainer.table_list.should =~ ['table1', 'table2']
    end
  end

  context 'when using store_in and with_databases' do
    before do
      SimpleDocument.store_in :database => ->{ @database }
    end

    it 'switches databases' do
      NoBrainer.with_database('test_db1') do
        SimpleDocument.create
        SimpleDocument.count.should == 1
      end

      NoBrainer.with_database('test_db1') do
        @database = 'test_db2'
        2.times { SimpleDocument.create }
        SimpleDocument.count.should == 2
      end

      NoBrainer.with_database('test_db1') do
        @database = nil
        SimpleDocument.count.should == 1
      end

      NoBrainer.with_database('test_db2') do
        @database = nil
        SimpleDocument.count.should == 2
      end
    end
  end
end
