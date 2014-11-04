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

  context 'when using regular strings' do
    context 'when not specifying orders' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by('field1', 'field2')
          .map(&:field1).should == [1,1,2,2]
      end
    end

    context 'when using :asc' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by('field1' => :asc)
          .map(&:field1).should == [1,1,2,2]
      end
    end

    context 'when using :desc' do
      it 'orders documents in descending order' do
        SimpleDocument.all.order_by('field1' => :desc)
          .map(&:field1).should == [1,1,2,2].reverse
      end
    end
  end

  context 'when using lambdas' do
    context 'when not specifying orders' do
      it 'orders documents in ascending order' do
        SimpleDocument.all.order_by { |doc| doc[:field1] + doc[:field2]  }
          .map { |doc| [doc.field1, doc.field2] }
          .should be_in [[[1,1],[1,2],[2,1],[2,2]], [[1,1],[2,1],[1,2],[2,2]]]
      end
    end

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
      SimpleDocument.field :field2,  :index => true
      SimpleDocument.index :field12, [:field1, :field2]
      NoBrainer.sync_indexes
    end

    after { NoBrainer.drop! }

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

    context 'when using an indexed filter' do
      it 'orders documents properly' do
        # between + indexed order_by works
        criteria = SimpleDocument.where(:field1.le => 2).order_by(:field1)
        criteria.map(&:field1).should == [1,1,2,2]
        criteria.where_indexed?.should == true
        criteria.order_by_indexed?.should == true

        # but not on a get_all...
        criteria = SimpleDocument.where(:field1 => 1).order_by(:field1)
        criteria.map(&:field1).should == [1,1]
        criteria.where_indexed?.should == true
        criteria.order_by_indexed?.should == false

        # if ambiguous, we can select the index to use
        criteria = SimpleDocument.where(:field1 => 1).order_by(:field2)
        criteria.with_index(:field1).map(&:field2).should == [1,2]
        criteria.with_index(:field1).where_indexed?.should == true
        criteria.with_index(:field1).order_by_indexed?.should == false

        criteria.with_index(:field2).map(&:field2).should == [1,2]
        criteria.with_index(:field2).where_indexed?.should == false
        criteria.with_index(:field2).order_by_indexed?.should == true
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

  context 'when using arrays' do
    it 'orders documents properly' do
      SimpleDocument.all.order_by([{:field1 => :asc}, {:field2 => :desc}])
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[1,1],[2,2],[2,1]]
    end
  end

  context 'when mixing the two by chaining two order_by calls' do
    it 'the latest wins' do
      SimpleDocument.order_by(:field1 => :asc).order_by(:field2 => :desc)
        .map(&:field2).should == [2,2,1,1]

      SimpleDocument.order_by(:field2 => :desc).order_by(:field1 => :asc)
        .map(&:field1).should == [1,1,2,2]
    end
  end

  context 'when using reverse_order' do
    it 'reverses the order' do
      SimpleDocument.all.order_by(:field1 => :asc, :field2 => :desc)
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[1,1],[2,2],[2,1]]

      SimpleDocument.all.order_by(:field1 => :asc, :field2 => :desc).reverse_order
        .map { |doc| [doc.field1, doc.field2] }
        .should == [[1,2],[1,1],[2,2],[2,1]].reverse
    end

    it 'gets reset by order_by' do
      SimpleDocument.reverse_order.order_by(:field1 => :desc)
        .map(&:field1).should == [2,2,1,1]
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

  context 'when using an empty clause' do
    it 'ignores it' do
      SimpleDocument.order_by().to_a.should == SimpleDocument.all.to_a
    end
  end
end
