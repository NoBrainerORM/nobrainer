require 'spec_helper'

describe 'lazy fetch' do
  before { load_simple_document }
  before { SimpleDocument.field :field2, :lazy_fetch => true }

  let!(:_doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }
  let!(:fields) { SimpleDocument.fields.keys.map(&:to_s) }

  it 'lazy fetches fields' do
    SimpleDocument.first.attributes.keys.should =~ fields - %w(field2)
    SimpleDocument.first.field2.should == 2

    doc = SimpleDocument.lazy_fetch(:field3).first
    doc.attributes.keys.should =~ fields - %w(field2 field3)
    doc.field3.should == 3
    doc.attributes.keys.should =~ fields - %w(field2)
    doc.field2.should == 2
    doc.attributes.keys.should =~ fields

    doc = SimpleDocument.lazy_fetch(:field2 => false, :field3 => true).first
    doc.attributes.keys.should =~ fields - %w(field3)
  end

  context 'when reloading' do
    it 'uses the model definition' do
      doc = SimpleDocument.lazy_fetch(:field3).first
      doc.attributes.keys.should =~ fields - %w(field2 field3)
      doc.field2.should == 2
      doc.attributes.keys.should =~ fields - %w(field3)
      doc.reload
      doc.attributes.keys.should =~ fields - %w(field2)
    end
  end

  context 'when using a default' do
    before { SimpleDocument.field :field2, :default => 10 }
    it 'uses the default' do
      SimpleDocument.delete_all
      SimpleDocument.insert_all({})
      expect(NoBrainer).to receive(:run).and_call_original.exactly(1).times
      SimpleDocument.first
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      SimpleDocument.first.field2.should == 10
    end
  end

  context 'when writing on a lazy field' do
    it 'does not try to fetch the old value' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      doc = SimpleDocument.first
      doc.field2 = 3
      doc.save
    end
  end

  context 'when using dirty' do
    it 'does not try to fetch the old value' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      doc = SimpleDocument.first
      doc.changes.should == {}
      doc.field2 = 3
      doc.field2_was.should be_a NoBrainer::Error::MissingAttribute
      doc.save
    end
  end
end
