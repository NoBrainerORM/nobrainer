require 'spec_helper'

describe 'NoBrainer aliases' do
  before { load_simple_document }

  before do
    SimpleDocument.field :field1, :as => :f1
    SimpleDocument.field :field2, :as => :f2
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
        NoBrainer.update_indexes
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ ['f1', 'field3']

        SimpleDocument.where(:field1 => 1).count.should == 1
      end

      it 'aliases queries' do
        NoBrainer.update_indexes
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
        NoBrainer.update_indexes
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
        SimpleDocument.index :field1, :as => 'index_f1'
        SimpleDocument.index :field3, :as => 'index_f3'
      end

      let!(:doc) { SimpleDocument.create(:field1 => 1) }

      it 'correctly uses the index' do
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ []
        NoBrainer.update_indexes
        NoBrainer.run(SimpleDocument.rql_table.index_list).should =~ ['index_f1', 'index_f3']

        SimpleDocument.where(:field1 => 1).count.should == 1
      end

      it 'aliases queries' do
        NoBrainer.update_indexes
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
        NoBrainer.update_indexes
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).count.should == 1
        SimpleDocument.where(:field1 => 1, :field2 => 2, :field3 => 3).used_index.should == :field123
      end
    end
  end
end
