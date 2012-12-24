require 'spec_helper'

describe 'NoBrainer ==' do
  before { load_models }

  let(:doc1) { BasicModel.create(:field1 => 'ohai') }
  let(:doc2) { BasicModel.create(:field1 => 'hello') }

  # XXX Is this correct behavior, even when the attributes are not the same?
  context 'when the ids are the same' do
    it 'returns true' do
      BasicModel.find(doc1.id).should == BasicModel.find(doc1.id)
    end
  end

  context 'when the ids are different' do
    it 'returns false' do
      BasicModel.find(doc1.id).should_not == BasicModel.find(doc2.id)
    end
  end

  context 'when the ids are both nil' do
    it 'returns false' do
      BasicModel.new.should_not == BasicModel.new
    end
  end

  context 'when compared to another object type' do
    it 'returns false' do
      BasicModel.find(doc1.id).should_not == doc1.id
    end
  end
end
