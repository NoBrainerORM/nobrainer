require 'spec_helper'

describe 'NoBrainer store_in' do
  before { load_simple_document }
  before do
    NoBrainer.drop!
    NoBrainer.db_list.select { |db| db =~ /^test_db[0-9]/ }.each do |db|
      NoBrainer.run_with(:db => db) { NoBrainer.drop! }
    end
  end
  after do
    NoBrainer.drop!
    NoBrainer.db_list.select { |db| db =~ /^test_db[0-9]/ }.each do |db|
      NoBrainer.run_with(:db => db) { NoBrainer.drop! }
    end
  end

  context 'when using the global wrapper' do
    it 'switches databases' do
      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.create
        SimpleDocument.count.should == 1
      end

      NoBrainer.run_with(:db => 'test_db2') do
        SimpleDocument.count.should == 0
        2.times { SimpleDocument.create }
        SimpleDocument.count.should == 2

        NoBrainer.run_with(:db => 'test_db1') do
          SimpleDocument.count.should == 1
        end

        SimpleDocument.count.should == 2
      end

      SimpleDocument.count.should == 0

      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.count.should == 1
        NoBrainer.drop!
      end

      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.count.should == 0
      end
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

  context 'when using store_in with symbols' do
    it 'converts names to strings' do
      SimpleDocument.store_in :table => :table1
      SimpleDocument.table_name.should == 'table1'
    end

    it 'converts lambda names to strings' do
      SimpleDocument.store_in :table => ->{ :table1 }
      SimpleDocument.table_name.should == 'table1'
    end
  end

  context 'when using multiple run_with' do
    it 'switches databases' do
      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.create
        SimpleDocument.count.should == 1
      end

      NoBrainer.run_with(:db => 'test_db2') do
        2.times { SimpleDocument.create }
        SimpleDocument.count.should == 2
      end

      SimpleDocument.count.should == 0

      NoBrainer.run_with(:db => 'test_db2') do
        SimpleDocument.count.should == 2
      end

      SimpleDocument.run_with(:db => 'test_db1').count.should == 1

      NoBrainer.run_with(:db => 'test_db2') do
        SimpleDocument.run_with(:db => 'test_db1').count.should == 1
      end

      NoBrainer.run_with(:db => 'test_db2') do
        NoBrainer.run_with(:db => 'test_db1') do
          SimpleDocument.count.should == 1
        end
      end
    end
  end
end
