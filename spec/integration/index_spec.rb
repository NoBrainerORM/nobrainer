require 'spec_helper'

describe 'NoBrainer index' do
  before { load_simple_document }
  before { NoBrainer.drop! }
  after  { NoBrainer.drop! }

  context 'when updating indexes' do
    it 'keeps indexes in sync' do
      SimpleDocument.index :field1
      NoBrainer.run { SimpleDocument.rql_table.index_list }.should =~ []
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.rql_table.index_list }.should =~ ['field1']
      SimpleDocument.index :field2
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.rql_table.index_list }.should =~ ['field1', 'field2']
      SimpleDocument.remove_index :field1
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.rql_table.index_list }.should =~ ['field2']
      SimpleDocument.remove_index :field2
      NoBrainer.update_indexes
      NoBrainer.run { SimpleDocument.rql_table.index_list }.should =~ []
    end
  end

  context 'when querying the primary key' do
    let!(:doc1) { SimpleDocument.create(:field1 => 'hello') }

    it 'uses the primary key index' do
      SimpleDocument.where(:id => doc1.id).indexed?.should == true
      SimpleDocument.where(:id => doc1.id).count.should == 1
      doc1.selector.indexed?.should == true
    end
  end

  context 'when indexing a field on a field declaration' do
    before do
      SimpleDocument.field :field4, :index => true
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field4 => 'hello') }
    let!(:doc2) { SimpleDocument.create(:field4 => 'ohai') }

    it 'uses the index' do
      SimpleDocument.where(:field4 => 'ohai').indexed?.should == true
      SimpleDocument.where(:field4 => 'ohai').count.should == 1
    end
  end

  context 'when indexing a field on a belongs_to' do
    before do
      load_blog_models
      Comment.belongs_to :post, :index => true
      NoBrainer.update_indexes
    end

    let!(:post)    { Post.create }
    let!(:comment) { Comment.create(:post => post) }

    it 'uses the index' do
      post.comments.indexed?.should == true
      post.comments.count.should == 1
    end
  end

  context 'when indexing a field normally' do
    before do
      SimpleDocument.index :field1
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'yay') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'world', :field2 => 'yay') }
    let!(:doc3) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'sup') }
    let!(:doc4) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'ola') }

    it 'uses the index' do
      SimpleDocument.where(:field1 => 'ohai').indexed?.should == true
      SimpleDocument.where(:field1 => 'ohai').count.should == 2
      SimpleDocument.where(:field2 => 'yay').indexed?.should == false
      SimpleDocument.where(:field2 => 'yay').count.should == 2
    end

    context 'when using a without_index where' do
      it 'does not use an index' do
        SimpleDocument.without_index.where(:field1 => 'ohai').indexed?.should == false
        SimpleDocument.without_index.where(:field1 => 'ohai').count.should == 2
        SimpleDocument.where(:field1 => 'ohai').without_index.indexed?.should == false
        SimpleDocument.where(:field1 => 'ohai').without_index.count.should == 2
      end
    end

    context 'when using multiple where' do
      it 'uses the index' do
        SimpleDocument.where(:field1 => 'ohai', :field2 => 'sup').indexed?.should == true
        SimpleDocument.where(:field1 => 'ohai', :field2 => 'sup').count.should == 1
      end
    end

    context 'when using in' do
      it 'uses the index' do
        SimpleDocument.where(:field1.in => ['hello', 'world']).indexed?.should == true
        SimpleDocument.where(:field1.in => ['hello', 'world']).count.should == 2
      end
    end
  end

  context 'when indexing two fields' do
    before do
      SimpleDocument.index :field1
      SimpleDocument.index :field2
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'yay') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the first declared index' do
      SimpleDocument.where(:field2 => 'yay', :field1 => 'ohai').used_index.should == :field1
      SimpleDocument.where(:field2 => 'yay', :field1 => 'ohai').count.should == 1
    end

    it 'allow to specify the index to be used' do
      SimpleDocument.with_index(:field1).where(:field2 => 'yay', :field1 => 'ohai').used_index.should == :field1
      SimpleDocument.with_index(:field1).where(:field2 => 'yay', :field1 => 'ohai').count.should == 1
      SimpleDocument.with_index(:field2).where(:field2 => 'yay', :field1 => 'ohai').used_index.should == :field2
      SimpleDocument.with_index(:field2).where(:field2 => 'yay', :field1 => 'ohai').count.should == 1

      expect { SimpleDocument.with_index(:field3).where(:field2 => 'yay', :field1 => 'ohai').count }
        .to raise_error(NoBrainer::Error::CannotUseIndex)
      expect { SimpleDocument.with_index(:field1).where(:field2 => 'yay').count }
        .to raise_error(NoBrainer::Error::CannotUseIndex)
    end
  end

  context 'when using a multi single field index' do
    before do
      SimpleDocument.field :field1, :index => {:multi => true}
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => ['hello', 'ohai']) }
    let!(:doc2) { SimpleDocument.create(:field1 => ['hello', 'world']) }
    let!(:doc3) { SimpleDocument.create(:field1 => ['this', 'is', 'fun']) }

    it 'uses the index' do
      SimpleDocument.where(:field1 => 'hello').count.should == 2
      SimpleDocument.where(:field1 => 'is').count.should == 1
      SimpleDocument.where(:field1 => ['hello', 'ohai']).count.should == 0
    end
  end

  context 'when indexing a field with a lambda' do
    before do
      SimpleDocument.index :field12, ->(doc){ doc['field1'] + "_" + doc['field2'] }
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index' do
      SimpleDocument.where(:field12 => 'hello_world').indexed?.should == true
      SimpleDocument.where(:field12 => 'hello_world').count.should == 1
    end

    it 'does not allow to use a field with the same name as an index' do
      SimpleDocument.index :index_name, ->(doc){}
      expect { SimpleDocument.field :index_name }.to raise_error
    end

    it 'does not allow to use an index with the same name' do
      SimpleDocument.field :field_name
      expect { SimpleDocument.index :field_name, ->(doc){} }.to raise_error
    end
  end

  context 'when indexing a compound field' do
    before do
      SimpleDocument.index :field12, [:field1, :field2]
      NoBrainer.update_indexes
    end

    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'ohai',  :field2 => 'yay') }

    it 'uses the index' do
      SimpleDocument.where(:field12 => ['hello', 'world']).indexed?.should == true
      SimpleDocument.where(:field12 => ['hello', 'world']).count.should == 1
    end

    it 'uses an index when possible' do
      SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').used_index.should == :field12
      SimpleDocument.where(:field1 => 'ohai', :field2 => 'yay').count.should == 1
    end

    it 'does not allow to use a field with the same name as an index' do
      SimpleDocument.index :index_name, [:field1, :field2]
      expect { SimpleDocument.field :index_name }.to raise_error
    end

    it 'does not allow to use an index with the same name' do
      SimpleDocument.field :field_name
      expect { SimpleDocument.index :field_name, [:field1, :field2] }.to raise_error
    end
  end

  context 'with a scope' do
    before do
      SimpleDocument.class_eval do
        SimpleDocument.index :field1
        default_scope { where(:field1 => 123) }
      end
    end

    it 'reports the index to be used' do
      SimpleDocument.indexed?.should == true
      SimpleDocument.used_index.should == :field1
    end
  end
end
