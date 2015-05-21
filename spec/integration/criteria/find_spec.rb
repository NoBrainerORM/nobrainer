require 'spec_helper'

describe 'find_by' do
  before { load_simple_document }

  it 'raises' do
    expect { SimpleDocument.find_by(:field1 => 'anything') }
    .to raise_error(/unclear semantics/)
  end
end

describe 'find' do
  before { load_simple_document }
  let!(:doc) { SimpleDocument.create(:field1 => 'apple', :field2 => 'orange') }

  context 'when using find' do
    it 'finds the document' do
      SimpleDocument.find?(doc.pk_value).field2.should == doc.field2
    end
  end

  context 'when no match is found' do
    it 'returns nil with find_by?' do
      SimpleDocument.find?('anything').should == nil
    end

    it 'raises with find' do
      expect { SimpleDocument.find('anything') }
        .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :#{SimpleDocument.pk_name}=>"anything" not found/)
    end

    it 'raises with find!' do
      expect { SimpleDocument.find!('anything') }
        .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :#{SimpleDocument.pk_name}=>"anything" not found/)
    end
  end

  context 'when applying a criteria' do
    it 'applies the criteria' do
      SimpleDocument.where(:field2 => 'orange').find(doc.pk_value).field2.should == 'orange'
    end
  end
end
