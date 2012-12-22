require 'spec_helper'

describe 'field definitions' do
  before { load_models }

  it 'persists' do
    doc = BasicModel.create(:field1 => 'hello')
    doc = BasicModel.find(doc.id)
    doc.field1.should == 'hello'

    doc.field1 = 'ohai'
    doc.field2 = ':)'
    doc.save

    doc = BasicModel.find(doc.id)
    doc.field1.should == 'ohai'
    doc.field2.should == ':)'
  end
end

describe 'find' do
  before { load_models }

  context 'when the document does not exist' do
    it 'throws not found error' do
      expect { BasicModel.find('x') }.to raise_error(NoBrainer::Error::NotFound)
    end
  end
end
