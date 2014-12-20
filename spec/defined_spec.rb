require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }

  context 'with validates_defined' do
    before { SimpleDocument.validates_defined :field1 }

    it 'cannot save without setting a value' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      expect { doc.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'cannot save a nil value' do
      doc = SimpleDocument.new field1: nil
      doc.valid?.should == false
      expect { doc.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save an empty string' do
      doc = SimpleDocument.new field1: ''
      doc.valid?.should == true
    end

    it 'can save a false value' do
      doc = SimpleDocument.new field1: false
      doc.valid?.should == true
    end

    it 'can save an empty array' do
      doc = SimpleDocument.new field1: []
      doc.valid?.should == true
    end
  end
end