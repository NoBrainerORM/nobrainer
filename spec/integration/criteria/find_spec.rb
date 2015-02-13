require 'spec_helper'

describe 'find_by' do
  before { load_simple_document }
  let!(:doc) { SimpleDocument.create(:field1 => 'apple', :field2 => 'orange') }

  context 'when using find_by' do
    it 'finds the document' do
      SimpleDocument.find_by?(:field1 => 'apple').field2.should == doc.field2
    end
  end

  context 'when passing a field that does not exist' do
    it 'raises when field is not exists' do
      expect { SimpleDocument.find_by?(:apple => 'field1') }.to raise_error(NoBrainer::Error::UnknownAttribute)
    end
  end

  context 'when no match is found' do
    it 'returns nil with find_by?' do
      SimpleDocument.find_by?(:field1 => 'anything').should == nil
    end

    it 'raises with find_by' do
      expect { SimpleDocument.find_by(:field1 => 'anything') }
        .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :field1=>"anything" not found/)
    end

    it 'raises with find_by!' do
      expect { SimpleDocument.find_by!(:field1 => 'anything') }
        .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :field1=>"anything" not found/)
    end
  end

  context 'when applying a criteria' do
    let!(:doc2) { SimpleDocument.create(:field1 => 'apple', :field2 => 'kiwi') }

    it 'applies the criteria' do
      SimpleDocument.where(:field2 => 'kiwi').find_by(:field1 => 'apple').field2.should == 'kiwi'
      SimpleDocument.where(:field2 => 'orange').find_by(:field1 => 'apple').field2.should == 'orange'
    end
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
