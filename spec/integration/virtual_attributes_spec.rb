require 'spec_helper'

describe 'types' do
  before { load_simple_document }
  let(:doc) { SimpleDocument.create(:field1 => "hello", :field2 => "world").tap { |d| d.reload }}

  context 'when using a rql expr' do
    before { SimpleDocument.virtual_field :vfield, ->(doc, r) { r.expr(3) }}

    it 'works' do
      doc.attributes.keys.should include("vfield")
      doc.vfield.should == 3
      SimpleDocument.first.vfield.should == 3
    end

    context 'when trying to write to the attribute' do
      it 'raises' do
        expect { doc.vfield = 3 }.to raise_error(NoBrainer::Error::ReadonlyField)
        expect { doc.write_attribute(:vfield, 3) }.to raise_error(NoBrainer::Error::ReadonlyField)
      end
    end
  end

  context 'when passing a block' do
    before { SimpleDocument.virtual_field(:vfield) { |doc, r| r.expr(3) } }
    it 'works' do
      doc.vfield.should == 3
    end
  end

  context 'when returning nil' do
    before { SimpleDocument.virtual_field :vfield, ->(doc, r) { nil }}
    it 'ignores the vfield' do
      doc.attributes.keys.should_not include("vfield")
    end
  end

  context 'when using dependent virtual attributes' do
    before { SimpleDocument.virtual_field :vfield1, ->(doc, r) { doc[:field1] + "_" + doc[:field2] } }
    before { SimpleDocument.virtual_field :vfield2, ->(doc, r) { doc[:vfield1] + "!" } }

    it 'works' do
      doc.vfield2.should == "hello_world!"
      doc.vfield1.should == "hello_world"
    end
  end

  context 'when using polymoprhic classes' do
    before { load_polymorphic_models }
    it 'does not work' do
      expect { Child.virtual_field :vfield, ->(doc, r){} }.to raise_error(/root class.*Parent/)
    end
  end
end
