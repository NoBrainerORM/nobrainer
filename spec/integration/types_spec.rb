require 'spec_helper'

describe 'types' do
  before { load_simple_document }
  before { SimpleDocument.field :field1, :type => type }
  let(:doc) { SimpleDocument.new }

  context 'when using String type' do
    let(:type) { String }

    context 'when fed with a symbol, string' do
      it 'casts the value' do
        doc.field1 = 'ohai'
        doc.field1.should == 'ohai'
        doc.valid?.should == true
        doc.field1 = :ohai
        doc.field1.should == 'ohai'
        doc.valid?.should == true
      end
    end

    context 'when fed with other values' do
      it 'invalidates the document and keep the original value' do
        doc.field1 = (1..2)
        doc.field1.should == (1..2)
        doc.valid?.should == false
        doc.errors.full_messages.first.should == "Field1 should be a string"

        doc.field1 = Symbol
        doc.field1.should == Symbol
        doc.valid?.should == false
        doc.errors.full_messages.first.should == "Field1 should be a string"
      end
    end

    context 'when changing from invalid to valid' do
      it 'passes the validations' do
        doc.field1 = (1..2)
        doc.valid?.should == false
        doc.field1 = 'ohai'
        doc.valid?.should == true
      end
    end
  end

  context 'when using Integer type' do
    let(:type) { Integer }

    it 'type checks and casts' do
      doc.field1 = 1
      doc.field1.should == 1
      doc.valid?.should == true
      doc.field1 = '1'
      doc.field1.should == 1
      doc.valid?.should == true
      doc.field1 = '+1 '
      doc.field1.should == 1
      doc.valid?.should == true
      doc.field1 = ' -1'
      doc.field1.should == -1
      doc.valid?.should == true

      doc.field1 = '=1'
      doc.field1.should == '=1'
      doc.valid?.should == false

      doc.field1 = 2**100
      doc.field1.should == 2**100
      doc.valid?.should == true
      doc.field1 = (2**100).to_s
      doc.field1.should == 2**100
      doc.valid?.should == true

      doc.field1 = 1.0
      doc.field1.should == 1
      doc.valid?.should == true
      doc.field1 = 1.1
      doc.field1.should == 1.1
      doc.valid?.should == false
      doc.field1 = ''
      doc.field1.should == ''
      doc.valid?.should == false
    end
  end

  context 'when using Float type' do
    let(:type) { Float }

    it 'type checks and casts' do
      doc.field1 = 1.1
      doc.field1.should == 1.1
      doc.valid?.should == true
      doc.field1 = '1'
      doc.field1.should == 1.0
      doc.valid?.should == true
      doc.field1 = '1.0'
      doc.field1.should == 1.0
      doc.valid?.should == true
      doc.field1 = '1.00'
      doc.field1.should == 1.00
      doc.valid?.should == true
      doc.field1 = '1.1'
      doc.field1.should == 1.1
      doc.valid?.should == true
      doc.field1 = '1.100'
      doc.field1.should == 1.1
      doc.valid?.should == true
      doc.field1 = '0.0'
      doc.field1.should == 0.0
      doc.valid?.should == true
      doc.field1 = '0'
      doc.field1.should == 0
      doc.valid?.should == true

      doc.field1 = '+1.1 '
      doc.field1.should == 1.1
      doc.valid?.should == true
      doc.field1 = ' -1.1'
      doc.field1.should == -1.1
      doc.valid?.should == true

      doc.field1 = '=1.1'
      doc.field1.should == '=1.1'
      doc.valid?.should == false

      doc.field1 = 'a0'
      doc.field1.should == 'a0'
      doc.valid?.should == false
      doc.field1 = ''
      doc.field1.should == ''
      doc.valid?.should == false

      doc.field1 = 1
      doc.field1.should == 1.0
      doc.valid?.should == true
    end
  end

  context 'when using Boolean type' do
    let(:type) { SimpleDocument::Boolean }

    it 'provides a ? method' do
      doc.field1 = true
      doc.field1?.should == true
      doc.field1 = false
      doc.field1?.should == false
    end

    it 'type checks and casts' do
      doc.field1 = true
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = false
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = ' tRue'
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = 'falSe '
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = 't'
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = 'f'
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = 'yEs'
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = 'no'
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = '1'
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = '0'
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = 1
      doc.field1.should == true
      doc.valid?.should == true
      doc.field1 = 0
      doc.field1.should == false
      doc.valid?.should == true

      doc.field1 = '2'
      doc.field1.should == '2'
      doc.valid?.should == false
      doc.field1 = 'blah'
      doc.field1.should == 'blah'
      doc.valid?.should == false
      doc.field1 = ''
      doc.field1.should == ''
      doc.valid?.should == false
      doc.field1 = 2
      doc.field1.should == 2
      doc.valid?.should == false
    end
  end

  context 'when using Symbol type' do
    let(:type) { Symbol }

    it 'type checks and casts' do
      doc.field1 = :ohai
      doc.field1.should == :ohai
      doc.valid?.should == true
      doc.field1 = 'ohai'
      doc.field1.should == :ohai
      doc.valid?.should == true
      doc.field1 = '   ohai   '
      doc.field1.should == :ohai
      doc.valid?.should == true
      doc.field1 = 123
      doc.field1.should == 123
      doc.valid?.should == false
      doc.field1 = ''
      doc.field1.should == ''
      doc.valid?.should == false
    end
  end

  context 'when using a non implemented type' do
    let(:type) { nil }
    before { define_constant(:CustomType) { } }
    before { SimpleDocument.field :field1, :type => CustomType }

    it 'type checks' do
      doc.field1 = CustomType.new
      doc.valid?.should == true
      doc.field1 = 123
      doc.valid?.should == false
      doc.errors.full_messages.first.should == "Field1 should be a custom type"
    end
  end

  context 'when coming from the database' do
    let(:type) { nil }
    it 'does not type check/cast' do
      doc.field1 = '1'
      doc.save
      SimpleDocument.first.field1.should == '1'
      SimpleDocument.field :field1, :type => Integer
      SimpleDocument.first.field1.should == '1'
    end
  end
end
