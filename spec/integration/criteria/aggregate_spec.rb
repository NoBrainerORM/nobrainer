require 'spec_helper'

describe "aggregate" do
  before { load_simple_document }

  context 'when there are documents' do
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

    context 'when using a lambda' do
      context 'when using min' do
        it 'computes the minimum' do
          SimpleDocument.min { |u| u['field1'] }.field1.should == 1
        end
      end

      context 'when using max' do
        it 'computes the maximum' do
          SimpleDocument.max { |u| u['field1'] }.field1.should == 10
        end
      end

      context 'when using sum' do
        it 'computes the sum' do
          SimpleDocument.sum { |u| u['field1'] }.should == (1..10).to_a.reduce(:+)
        end
      end

      context 'when using avg' do
        it 'computes the avg' do
          SimpleDocument.avg { |u| u['field1'] }.should == (1..10).to_a.reduce(:+).to_f/10
        end
      end
    end
  end

  context 'when there are no documents' do
    context 'when using min' do
      it 'returns nil' do
        SimpleDocument.min(:field1).should == nil
      end
    end

    context 'when using max' do
      it 'returns nil' do
        SimpleDocument.max(:field1).should == nil
      end
    end

    context 'when using sum' do
      it 'returns 0' do
        SimpleDocument.sum(:field1).should == 0
      end
    end

    context 'when using avg' do
      it 'computes the avg' do
        SimpleDocument.avg(:field1).should == nil
      end
    end
  end
end
