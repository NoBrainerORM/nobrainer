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
  
  context 'when passing multiple pks to find' do
     let(:doc2) { SimpleDocument.create(:field1 => 'banana', :field2 => 'grape') }
     let(:doc3) { SimpleDocument.create(:field1 => 'blueberry', :field2 => 'strawberry') }
     
     it 'returns both documents' do
       pks = [doc, doc2].map(&:pk_value)
       docs = SimpleDocument.find(pks)
       expect(docs).to contain_exactly(doc, doc2)
     end     
     
     it 'is chainable' do
       pks = [doc, doc2].map(&:pk_value)
       SimpleDocument.find(pks).count.should == 2
     end   
     
     it 'returns an array if passed an array' do
       ary = SimpleDocument.find([doc.pk_value])
       expect(ary).to be_an(Array)
       expect(ary).to contain_exactly(doc)
     end 

     it 'respects "limit"' do
       pks = [doc, doc2, doc3].map(&:pk_value)
       SimpleDocument.find(pks).size.should == 3
       SimpleDocument.find(pks).limit(2).size.should == 2
     end
    
    it 'it returns [] for passing [] with find_by?' do
      docs = SimpleDocument.find?([])
      expect(docs).to be == []
    end

    context 'with missing pks' do
      let(:pks) { [doc, doc2, doc3].map(&:pk_value) << 'anything' << 'something' }
      
      it 'it returns nil for missing pk with find_by?' do
        docs = SimpleDocument.find?(pks)
        expect(docs).to contain_exactly(doc, doc2, doc3)
        docs = SimpleDocument.find?(nil)
        expect(docs).to be_nil        
      end
      
      it 'it raises with find' do
        expect { SimpleDocument.find(pks) }
          .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :#{SimpleDocument.pk_name}=>"anything, something" not found/)
      end

      it 'it raises with find!' do
        expect { SimpleDocument.find!(pks) }
          .to raise_error(NoBrainer::Error::DocumentNotFound, /SimpleDocument :#{SimpleDocument.pk_name}=>"anything, something" not found/)
      end    
    end
  end
end
