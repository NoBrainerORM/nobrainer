require 'spec_helper'

describe "NoBrainer selection" do
  before { load_simple_document }

  context 'when the document does not exist' do
    describe 'find' do
      it 'returns nil' do
        SimpleDocument.find('x').should == nil
      end
    end

    describe 'find!' do
      it 'throws not found error' do
        expect { SimpleDocument.find!('x') }.to raise_error(NoBrainer::Error::DocumentNotFound)
      end
    end
  end

  describe 'update' do
    it 'updates documents' do
      SimpleDocument.create(:field1 => 'ohai')
      SimpleDocument.create(:field1 => 'ohai')

      SimpleDocument.where(:field1 => 'hello').count.should == 0
      SimpleDocument.all.update(:field1 => 'hello')
      SimpleDocument.where(:field1 => 'hello').count.should == 2
    end
  end
end
