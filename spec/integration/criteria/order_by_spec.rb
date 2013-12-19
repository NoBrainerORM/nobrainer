require 'spec_helper'

describe 'order_by' do
  before { load_simple_document }

  let!(:docs) do
    2.times do |i|
      2.times do |j|
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
end
