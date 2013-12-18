require 'spec_helper'

describe 'NoBrainer index' do
  before { load_simple_document }
  before { NoBrainer.purge! :drop => true }
  after  { NoBrainer.purge! :drop => true }

  context 'when indexing a field normally' do
    before do
      SimpleDocument.index :field1
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai') }

    it 'uses the index with indexed()' do
      SimpleDocument.indexed(:field1 => 'ohai').count.should == 1
    end
  end

  context 'when indexing a field on a field declaration' do
    before do
      SimpleDocument.field :field4, :index => true
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field4 => 'hello') }
    let!(:doc2) { SimpleDocument.create(:field4 => 'ohai') }

    it 'uses the index with indexed()' do
      SimpleDocument.indexed(:field4 => 'ohai').count.should == 1
    end
  end

  context 'when indexing a field with a lambda' do
    before do
      SimpleDocument.index :field12, ->(doc){ doc['field1'] + "_" + doc['field2'] }
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index with indexed()' do
      SimpleDocument.indexed(:field12 => 'hello_world').count.should == 1
    end
  end

  context 'when indexing a compound field' do
    before do
      SimpleDocument.index :field12, [:field1, :field2]
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index with indexed()' do
      SimpleDocument.indexed(:field12 => ['hello', 'world']).count.should == 1
    end
  end

  context 'when updating indexes' do
    it 'keeps indexes in sync' do
      SimpleDocument.index :field1
      NoBrainer.run { SimpleDocument.table.index_list }.should =~ []
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.table.index_list }.should =~ ['field1']
      SimpleDocument.index :field2
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.table.index_list }.should =~ ['field1', 'field2']
      SimpleDocument.remove_index :field1
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.table.index_list }.should =~ ['field2']
      SimpleDocument.remove_index :field2
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.table.index_list }.should =~ []
    end
  end
end
