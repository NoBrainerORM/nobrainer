require 'spec_helper'

describe 'find_by' do
  before { load_simple_document }

  context 'when using find_by' do
    it 'find document' do
      SimpleDocument.create(:field1 => 'apple', :field2 => 'orange')
      SimpleDocument.find_by(:field1 => 'apple').field2.should == 'orange'
    end

  end

  context 'when passing a field that does not exist' do
    it 'raise when field is not exists' do
      expect { SimpleDocument.find_by!(:apple => 'field1') }.to raise_error NoBrainer::Error::UnknownAttribute
    end
  end

  context 'when document is not present' do
    it 'return nil when document is not present' do
      SimpleDocument.find_by(:field1 => 'anything').should == nil
    end
    it 'raise when document is not present' do
      expect { SimpleDocument.find_by!(:field1 => 'anything') }.to raise_error NoBrainer::Error::DocumentNotFound
    end
  end
end
