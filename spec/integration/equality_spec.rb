require 'spec_helper'

describe 'NoBrainer ==' do
  before { load_simple_document }

  let(:doc1) { SimpleDocument.create(:field1 => 'ohai') }
  let(:doc2) { SimpleDocument.create(:field1 => 'hello') }

  # XXX Is this correct behavior, even when the attributes are not the same?
  context 'when the ids are the same' do
    it 'returns true' do
      SimpleDocument.find(doc1.pk_value).should == SimpleDocument.find(doc1.pk_value)
    end
  end

  context 'when the ids are different' do
    it 'returns false' do
      SimpleDocument.find(doc1.pk_value).should_not == SimpleDocument.find(doc2.pk_value)
    end
  end
  context 'when object are new' do
    it 'returns false' do
      SimpleDocument.new.should_not == SimpleDocument.new
    end
  end

  context 'when using custom primary keys' do
    after { NoBrainer.drop! }
    it 'acts on the primary keys' do
      SimpleDocument.field :pk, :primary_key => true
      SimpleDocument.new(:pk => 1).should_not == SimpleDocument.new(:pk => 2)
      SimpleDocument.new(:pk => 1).should     == SimpleDocument.new(:pk => 1)
    end
  end

  context 'when the primary keys are both nil' do
    after { NoBrainer.drop! }
    it 'returns false' do
      SimpleDocument.field :pk, :primary_key => true
      SimpleDocument.new(:pk => nil).should_not == SimpleDocument.new(:pk => nil)
    end
  end

  context 'when compared to another object type' do
    it 'returns false' do
      SimpleDocument.find(doc1.pk_value).should_not == doc1.pk_value
    end
  end

  context 'when using a hash' do
    it 'hashes things properly' do
      hash = {}
      hash[SimpleDocument.find(doc1.pk_value)] = true
      hash[SimpleDocument.find(doc2.pk_value)] = true
      hash[SimpleDocument.find(doc1.pk_value)] = true
      hash[SimpleDocument.find(doc2.pk_value)] = true
      hash.size.should == 2
    end
  end
end
