require 'spec_helper'

describe 'NoBrainer ==' do
  before { load_simple_document }

  let(:doc1) { SimpleDocument.create(:field1 => 'ohai') }
  let(:doc2) { SimpleDocument.create(:field1 => 'hello') }

  # XXX Is this correct behavior, even when the attributes are not the same?
  context 'when the ids are the same' do
    it 'returns true' do
      SimpleDocument.find(doc1.id).should == SimpleDocument.find(doc1.id)
    end
  end

  context 'when the ids are different' do
    it 'returns false' do
      SimpleDocument.find(doc1.id).should_not == SimpleDocument.find(doc2.id)
    end
  end

  context 'when the ids are both nil' do
    it 'returns false' do
      SimpleDocument.new.should_not == SimpleDocument.new
    end
  end

  context 'when compared to another object type' do
    it 'returns false' do
      SimpleDocument.find(doc1.id).should_not == doc1.id
    end
  end
end
