require 'spec_helper'

describe "after_find" do
  before { load_simple_document }
  before { SimpleDocument.create }

  context 'when using after_find model callbacks' do
    it 'calls the after_find' do
      SimpleDocument.after_find(->(doc) { doc.field1 = 'hello' })
      SimpleDocument.after_find { |doc| doc.field2 = 'world' }
      doc = SimpleDocument.first
      doc.field1.should == 'hello'
      doc.field2.should == 'world'
      doc.reload
      doc.field1.should == nil
      doc.field2.should == nil
    end
  end

  context 'when using after_find criteria callbacks' do
    it 'calls the after_find' do
      criteria = SimpleDocument.all
        .after_find(->(doc) { doc.field1 = 'hello' })
        .after_find { |doc| doc.field2 = 'world' }
      doc = criteria.first
      doc.field1.should == 'hello'
      doc.field2.should == 'world'
      doc.reload
      doc.field1.should == nil
      doc.field2.should == nil
    end
  end

  context 'when using after_find criteria callbacks on a raw document' do
    it 'calls the after_find' do
      doc = nil
      criteria = SimpleDocument.all.raw.after_find { |d| doc = d }
      criteria.first.should == doc
      doc[SimpleDocument.pk_name.to_s].should == SimpleDocument.first.pk_value
    end
  end
end
