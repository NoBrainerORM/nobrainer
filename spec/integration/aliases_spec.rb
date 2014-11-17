require 'spec_helper'

describe 'NoBrainer aliases' do
  before { load_simple_document }

  before do
    SimpleDocument.field :field1, :store_as => :f1
    SimpleDocument.field :field2, :store_as => :f2
  end

  context 'when using no indexes' do
    context 'when using regular queries' do
      let!(:doc) { SimpleDocument.create(:field1 => 1) }

      it 'aliases fields model->db' do
        SimpleDocument.raw.first['f1'].should == 1
      end

      it 'aliases fields db->model' do
        SimpleDocument.first.field1.should == 1
      end

      it 'aliases where queries' do
        SimpleDocument.where(:field1 => 1).count.should == 1
      end

      it 'aliases order_by queries' do
        SimpleDocument.create(:field1 => 2)
        SimpleDocument.order_by(:field1 => :asc).map(&:field1).should == [1,2]
        SimpleDocument.order_by(:field1 => :desc).map(&:field1).should == [2,1]
      end
    end
  end

  context 'when using non aliased indexes' do
    before { NoBrainer.drop! }
    after  { NoBrainer.drop! }

    context 'when using a simple index' do
      before do
        SimpleDocument.index :field1
        SimpleDocument.index :field3
      end

      let!(:doc1) { SimpleDocument.create(:field1 => 1) }

      it 'correctly uses the index' do
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ []
        NoBrainer.sync_indexes
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ ['f1', 'field3']

        SimpleDocument.where(:field1 => 1).count.should == 1
      end

      it 'aliases queries' do
        NoBrainer.sync_indexes
        SimpleDocument.create(:field1 => 2)
        SimpleDocument.where(:field1 => 1).count.should == 1
        SimpleDocument.order_by(:field1 => :asc).map(&:field1).should == [1,2]
        SimpleDocument.order_by(:field1 => :desc).map(&:field1).should == [2,1]
      end
    end

    context 'when using a compound index' do
      before do
        SimpleDocument.index :field123, [:field1, :field2, :field3]
      end

      let!(:doc1) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

      it 'correctly ues the index' do
        NoBrainer.sync_indexes
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).count.should == 1
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).used_index.should == :field123
      end
    end
  end

  context 'when using aliased indexes' do
    before { NoBrainer.drop! }
    after  { NoBrainer.drop! }

    context 'when using a simple index' do
      before do
        SimpleDocument.index :field1, :store_as => 'index_f1'
        SimpleDocument.index :field3, :store_as => 'index_f3'
      end

      let!(:doc) { SimpleDocument.create(:field1 => 1) }

      it 'correctly uses the index' do
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ []
        NoBrainer.sync_indexes
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ ['index_f1', 'index_f3']

        SimpleDocument.where(:field1 => 1).count.should == 1
      end

      it 'aliases queries' do
        NoBrainer.sync_indexes
        SimpleDocument.create(:field1 => 2)
        SimpleDocument.where(:field1 => 1).count.should == 1
        SimpleDocument.order_by(:field1 => :asc).map(&:field1).should == [1,2]
        SimpleDocument.order_by(:field1 => :desc).map(&:field1).should == [2,1]
      end
    end

    context 'when using a compound index' do
      before do
        SimpleDocument.index :field123, [:field1, :field2, :field3]
      end

      let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

      it 'correctly ues the index' do
        NoBrainer.sync_indexes
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).count.should == 1
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).used_index.should == :field123
      end
    end
  end

  context 'when using insert_all' do
    it 'aliases fields' do
      SimpleDocument.insert_all(100.times.map { |i| {:field1 => i+1} })
      SimpleDocument.count.should == 100
      SimpleDocument.where(:field1.gt 50).count.should == 50
    end
  end

  context 'when using update_all' do
    let!(:doc) { SimpleDocument.create(:field1 => 1) }

    it 'aliases fields' do
      SimpleDocument.update_all(:field1 => 2)
      SimpleDocument.where(:field1 => 2).count.should == 1
      SimpleDocument.replace_all(doc.attributes.merge('field1' => 3))
      SimpleDocument.where(:field1 => 3).count.should == 1
    end
  end

  context 'when using aggregates' do
    before { 10.times { |i| SimpleDocument.create(:field1 => i+1) } }
    context 'when using a field' do
      context 'when using min' do
        it 'computes the minimum' do
          SimpleDocument.min(:field1).field1.should == 1
          SimpleDocument.where(:field1.gt 5).min(:field1).field1.should == 6
        end
      end

      context 'when using max' do
        it 'computes the maximum' do
          SimpleDocument.max(:field1).field1.should == 10
          SimpleDocument.where(:field1.lt 5).max(:field1).field1.should == 4
        end
      end

      context 'when using sum' do
        it 'computes the sum' do
          SimpleDocument.sum(:field1).should == (1..10).to_a.reduce(:+)
          SimpleDocument.where(:field1.lt 5).sum(:field1).should == (1..4).to_a.reduce(:+)
        end
      end

      context 'when using avg' do
        it 'computes the avg' do
          SimpleDocument.avg(:field1).should == (1..10).to_a.reduce(:+).to_f/10
          SimpleDocument.where(:field1.lt 5).avg(:field1).should == (1..4).to_a.reduce(:+).to_f/4
        end
      end
    end
  end

  context 'when using associations' do
    before do
      load_blog_models
      Post.belongs_to :author, :foreign_key_store_as => :a_id
      Comment.belongs_to :post, :foreign_key_store_as => :p_id

      Comment.has_one :author, :through => :post
    end

    let!(:author)  { Author.create }
    let!(:post)    { Post.create(:author => author) }
    let!(:comment) { Comment.create(:post => post) }

    it 'aliases' do
      Post.raw.first['a_id'].should == author.pk_value
      Post.first.author.should == author
      Comment.first.author.should == author
      Author.preload(:posts => Post.preload(:comments)).first.posts.first.comments.first.should == comment
    end
  end
end
