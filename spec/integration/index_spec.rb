require 'spec_helper'

describe 'NoBrainer index' do
  before { load_simple_document }
  before { NoBrainer.drop! }
  after  { NoBrainer.drop! }

  context 'when indexing a field normally' do
    before do
      SimpleDocument.index :field1
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai') }

    it 'uses the index with indexed_where()' do
      SimpleDocument.indexed_where(:field1 => 'ohai').count.should == 1
    end
  end

  context 'when indexing a field on a field declaration' do
    before do
      SimpleDocument.field :field4, :index => true
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field4 => 'hello') }
    let!(:doc2) { SimpleDocument.create(:field4 => 'ohai') }

    it 'uses the index with indexed_where()' do
      SimpleDocument.indexed_where(:field4 => 'ohai').count.should == 1
    end
  end

  context 'when indexing a field on a belongs_to' do
    before do
      load_blog_models
      Comment.belongs_to :post, :index => true
      NoBrainer.update_indexes
    end

    let!(:post)    { Post.create }
    let!(:comment) { post.comments.create }

    it 'uses the index with indexed_where()' do
      Comment.indexed_where(:post_id => post.id).count.should == 1
    end
  end

  context 'when indexing a field with a lambda' do
    before do
      SimpleDocument.index :field12, ->(doc){ doc['field1'] + "_" + doc['field2'] }
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index with indexed_where()' do
      SimpleDocument.indexed_where(:field12 => 'hello_world').count.should == 1
    end
  end

  context 'when indexing a compound field' do
    before do
      SimpleDocument.index :field12, [:field1, :field2]
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index with indexed_where()' do
      SimpleDocument.indexed_where(:field12 => ['hello', 'world']).count.should == 1
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

  context 'when using a single field index' do
    before do
      SimpleDocument.field :field1, :index => true
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'yay') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }
    let!(:doc3) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'ola') }

    context 'when using a single where' do
      it 'uses an index when possible' do
        expect { SimpleDocument.where(:field1 => 'ohai').count }
          .to raise_error(RethinkDB::RqlRuntimeError)
        NoBrainer.update_indexes
        SimpleDocument.where(:field1 => 'ohai').count.should == 2
      end
    end

    context 'when using a without_index where' do
      it 'uses an index when possible' do
        SimpleDocument.without_index.where(:field1 => 'ohai').count.should == 2
        SimpleDocument.where(:field1 => 'ohai').without_index.count.should == 2
      end
    end

    context 'when using multiple where' do
      it 'uses an index when possible' do
        expect { SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').count }
          .to raise_error(RethinkDB::RqlRuntimeError)
        NoBrainer.update_indexes
        SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').count.should == 1
      end
    end
  end

  context 'when using a compound field index' do
    before do
      SimpleDocument.index :field12, [:field1, :field2]
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'yay', :field3 => 'cheeze') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay', :field3 => 'steak') }
    let!(:doc3) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay', :field3 => 'bread') }
    let!(:doc4) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'ola', :field3 => 'letuce') }

    context 'when using multiple where' do
      it 'uses an index when possible' do
        expect { SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').count }
          .to raise_error(RethinkDB::RqlRuntimeError)
        expect { SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay', :field3 => 'bread').count }
          .to raise_error(RethinkDB::RqlRuntimeError)

        NoBrainer.update_indexes

        SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').count.should == 2
        SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay', :field3 => 'bread').count.should == 1
      end
    end
  end
end
