require 'spec_helper'

describe 'first' do
  before { load_simple_document }

  context 'when there exist some documents' do
    let!(:documents) { 5.times.map { |i| SimpleDocument.create(:field1 => i) } }

    context 'when not using a scope' do
      describe 'first' do
        it 'returns the first document' do
          SimpleDocument.first.id.should == documents.first.id
        end
      end

      describe 'last' do
        it 'returns the last document' do
          SimpleDocument.last.id.should == documents.last.id
        end
      end
    end

    context 'when using a scope' do
      describe 'first' do
        it 'returns the document' do
          SimpleDocument.where(:field1 => 3).first.id.should == documents[3].id
        end
      end

      describe 'last' do
        it 'returns the document' do
          SimpleDocument.where(:field1 => 4).last.id.should == documents[4].id
        end
      end
    end
  end

  context 'when there are no documents' do
    describe 'first' do
      it 'returns nil' do
        SimpleDocument.first.should == nil
      end
    end

    describe 'last' do
      it 'returns nil' do
        SimpleDocument.last.should == nil
      end
    end
  end
end
