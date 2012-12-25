require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }

  before { SimpleDocument.validates :field1, :presence => true }

  it 'responds to valid?' do
    doc = SimpleDocument.new
    doc.valid?.should == false
    doc.field1 = 'hey'
    doc.valid?.should == true
  end

  it 'adds errors' do
    SimpleDocument.create.errors.should be_present
  end

  context 'when not using the bang version' do
    let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

    it 'prevents create if invalid' do
      # TODO write better test with count
      SimpleDocument.create.id.should == nil
    end

    context 'when passing :validate => false' do
      it 'returns true for save' do
        doc.field1 = nil
        doc.save(:validate => false).should == true
      end
    end

    context 'when passing nothing' do
      it 'returns false for save' do
        doc.field1 = nil
        doc.save.should == false
      end
    end

    it 'returns false for update_attributes' do
      doc.update_attributes(:field1 => nil).should == false
    end

    it 'returns false for update_attribute' do
      doc.update_attribute(:field1, nil).should == false
    end
  end

  context 'when using the bang version' do
    let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

    it 'throws an exception for create!' do
      expect { SimpleDocument.create! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    context 'when passing :validate => false' do
      it 'returns true for save!' do
        doc.field1 = nil
        doc.save!(:validate => false).should == true
      end
    end

    context 'when passing nothing' do
      it 'throws an exception for save!' do
        doc.field1 = nil
        expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end

    it 'throws an exception for update_attributes!' do
      expect { doc.update_attributes!(:field1 => nil) }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'throws an exception for update_attribute!' do
      expect { doc.update_attribute!(:field1, nil) }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end
  end
end
