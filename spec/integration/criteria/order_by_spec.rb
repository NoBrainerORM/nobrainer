require 'spec_helper'

describe 'order_by' do
  before { load_simple_document }

  let!(:docs) do
    2.times.to_a.shuffle.each do |i|
      2.times.to_a.shuffle.each do |j|
        SimpleDocument.create(:field1 => i+1, :field2 => j+1)
      end
    end
  end

  context 'when using regular symbols' do
    context 'when not specifying orders' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by(:field1, :field2)
          .map(&:field1).should == [1,1,2,2]
      end
    end

    context 'when using :asc' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by(:field1 => :asc)
          .map(&:field1).should == [1,1,2,2]
      end
    end

    context 'when using :desc' do
      it 'orders documents in descending order' do
        SimpleDocument.all.order_by(:field1 => :desc)
          .map(&:field1).should == [1,1,2,2].reverse
      end
    end
  end

  context 'when using lambdas' do
    context 'when not specifying orders' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by(->(doc) { doc[:field1] + doc[:field2] })
          .map { |doc| [doc.field1, doc.field2] }
          .should be_in [[[1,1],[1,2],[2,1],[2,2]], [[1,1],[2,1],[1,2],[2,2]]]
      end
    end

    context 'when using :asc' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by(->(doc) { doc[:field1] + doc[:field2] } => :asc)
          .map { |doc| [doc.field1, doc.field2] }
          .should be_in [[[1,1],[1,2],[2,1],[2,2]], [[1,1],[2,1],[1,2],[2,2]]]
      end
    end

    context 'when using :desc' do
      it 'orders documents in descending order' do
        SimpleDocument.all.order_by(->(doc) { doc[:field1] + doc[:field2] } => :desc)
          .map { |doc| [doc.field1, doc.field2] }
          .should be_in [[[2,2],[1,2],[2,1],[1,1]], [[2,2],[2,1],[1,2],[1,1]]]
      end
    end
  end

  context 'when using indexes' do
    before do
      SimpleDocument.field :field1,  :index => true
      SimpleDocument.index :field12, [:field1, :field2]
      NoBrainer.update_indexes
    end

    context 'when not specifying orders' do
      context 'when using order_by with implicit indexes' do
        it 'orders documents properly' do
          SimpleDocument.order_by(:field1)
            .map(&:field1).should == [1,1,2,2]
          SimpleDocument.order_by(:field12)
            .map { |doc| [doc.field1, doc.field2] }
            .should == [[1,1],[1,2],[2,1],[2,2]]
        end
      end

      context 'when using a without_index order_by' do
        it 'orders documents properly' do
          SimpleDocument.without_index.order_by(:field1)
            .map(&:field1).should == [1,1,2,2]
          SimpleDocument.without_index.order_by(:field12)
            .map { |doc| [doc.field1, doc.field2] }
            .should_not == [[1,1],[1,2],[2,1],[2,2]]
        end
      end
    end

    context 'when using :asc' do
      context 'when using order_by with implicit indexes' do
        it 'orders documents properly' do
          SimpleDocument.order_by(:field1 => :asc)
            .map(&:field1).should == [1,1,2,2]
          SimpleDocument.order_by(:field12 => :asc)
            .map { |doc| [doc.field1, doc.field2] }
            .should == [[1,1],[1,2],[2,1],[2,2]]
        end
      end

      context 'when using a without_index order_by' do
        it 'orders documents properly' do
          SimpleDocument.without_index.order_by(:field1 => :asc)
            .map(&:field1).should == [1,1,2,2]
          SimpleDocument.without_index.order_by(:field12 => :asc)
            .map { |doc| [doc.field1, doc.field2] }
            .should_not == [[1,1],[1,2],[2,1],[2,2]]
        end
      end
    end

    context 'when using :desc' do
      context 'when using order_by with implicit indexes' do
        it 'orders documents properly' do
          SimpleDocument.order_by(:field1 => :desc)
            .map(&:field1).should == [2,2,1,1]
          SimpleDocument.order_by(:field12 => :desc)
            .map { |doc| [doc.field1, doc.field2] }
            .should == [[2,2],[2,1],[1,2],[1,1]]
        end
      end

      context 'when using a without_index order_by' do
        it 'orders documents properly' do
          SimpleDocument.without_index.order_by(:field1 => :desc)
            .map(&:field1).should == [2,2,1,1]
          SimpleDocument.without_index.order_by(:field12 => :desc)
            .map { |doc| [doc.field1, doc.field2] }
            .should_not == [[2,2],[2,1],[1,2],[1,1]]
        end
      end
    end

    context 'when mixing non indexed and indexed fields' do
      it 'orders documents properly' do
        SimpleDocument.order_by(:field2, :field1)
          .map { |doc| [doc.field1, doc.field2] }
          .should == [[1,1],[2,1],[1,2],[2,2]]

        SimpleDocument.order_by(:field1, :field2)
          .map { |doc| [doc.field1, doc.field2] }
          .should == [[1,1],[1,2],[2,1],[2,2]]
      end
    end
  end

  context 'when mixing the two with on order_by call' do
    it 'orders documents properly' do
      SimpleDocument.all.order_by(:field1 => :asc, :field2 => :desc)
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[1,1],[2,2],[2,1]]

      SimpleDocument.all.order_by(:field2 => :desc, :field1 => :asc)
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[2,2],[1,1],[2,1]]
    end
  end

  context 'when mixing the two by chaining two order_by calls' do
    it 'orders documents properly' do
      SimpleDocument.all.order_by(:field1 => :asc,).order_by(:field2 => :desc)
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[1,1],[2,2],[2,1]]

      SimpleDocument.all.order_by(:field2 => :desc).order_by(:field1 => :asc)
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[2,2],[1,1],[2,1]]
    end
  end

  context 'when using a scope' do
    before do
      SimpleDocument.class_eval do
        default_scope { order_by(:field1 => :desc) }
      end
    end

    it 'uses the scope properly' do
      SimpleDocument.first.field1.should == 2
      SimpleDocument.last.field1.should == 1
    end

    it 'applies the default scope first' do
      SimpleDocument.order_by(:field1 => :asc).first.field1.should == 1
    end
  end
end
