require 'spec_helper'

describe 'definition validator' do
  before { load_simple_document }

  context 'with :required => true on Boolean' do
    before { SimpleDocument.field :field1, :type => SimpleDocument::Boolean, :required => true }

    it 'cannot save without setting a value' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      doc.errors.full_messages.first.should == 'Field1 must be defined'
    end

    it 'cannot save a nil value' do
      doc = SimpleDocument.new(:field1 => nil)
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save a false value' do
      doc = SimpleDocument.new(:field1 => false)
      doc.valid?.should == true
    end
  end

  context 'with :required => true on String' do
    before { SimpleDocument.field :field1, :type => String, :required => true }

    it 'cannot save without setting a value' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      doc.errors.full_messages.first.should == "Field1 can't be blank"
    end

    it 'cannot save a nil value' do
      doc = SimpleDocument.new(:field1 => nil)
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'cannot save an empty string' do
      doc = SimpleDocument.new(:field1 => '')
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end
  end

  context 'with validates_not_null' do
    before { SimpleDocument.validates_not_null :field1 }

    it 'cannot save without setting a value' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      doc.errors.full_messages.first.should == 'Field1 must be defined'
    end

    it 'cannot save a nil value' do
      doc = SimpleDocument.new(:field1 => nil)
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save an empty string' do
      doc = SimpleDocument.new(:field1 => '')
      doc.valid?.should == true
    end

    it 'can save a false value' do
      doc = SimpleDocument.new(:field1 => false)
      doc.valid?.should == true
    end

    it 'can save an empty array' do
      doc = SimpleDocument.new(:field1 => [])
      doc.valid?.should == true
    end
  end

  context 'with validates_presence_of' do
    before { SimpleDocument.validates_presence_of :field1 }

    it 'cannot save without setting a value' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      doc.errors.full_messages.first.should == "Field1 can't be blank"
    end

    it 'cannot save a nil value' do
      doc = SimpleDocument.new(:field1 => nil)
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'cannot save an empty string' do
      doc = SimpleDocument.new(:field1 => '')
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'cannot save a false value' do
      doc = SimpleDocument.new(:field1 => false)
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'cannot save an empty array' do
      doc = SimpleDocument.new(:field1 => [])
      doc.valid?.should == false
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end
  end
end
