require 'spec_helper'

describe 'NoBrainer persistance' do
  before { load_simple_document }

  let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

  it 'persist fields on creation' do
    doc.reload
    doc.field1.should == 'hello'
    doc.field2.should == 'world'
  end

  it 'updates with save' do
    doc.field1 = 'ohai'
    doc.field2 = ':)'
    doc.save
    doc.reload
    doc.field1.should == 'ohai'
    doc.field2.should == ':)'
  end

  it 'updates with update_attributes' do
    doc.update_attributes(:field1 => 'please', :field2 => 'halp')
    doc.reload
    doc.field1.should == 'please'
    doc.field2.should == 'halp'
  end

  #TODO: Submitted https://github.com/rethinkdb/rethinkdb/issues/194 to allow for value of
  # updated doc to be returned atomically
  it 'updates atomically with update' do
    doc.field1 = 1
    doc.save

    doc.update do |document|
      { :field1 => document[:field1] + 1 }
    end.should == true

    doc.reload
    doc.field1.should == 2
  end

  it 'deletes' do
    doc.delete.should == true
    SimpleDocument.find(doc.id).should == nil
  end

  context 'when using default reload' do
    it 'reloads and cleans up ivars' do
      doc.instance_eval { @some_ivar = true }
      doc.field2 = 'brave world'
      doc.reload.should == doc
      doc.field2.should == 'world'
      doc.instance_eval { @some_ivar }.should == nil
    end
  end

  context 'when using reload with keep_ivars' do
    it 'reloads and cleans up ivars' do
      doc.instance_eval { @some_ivar = true }
      doc.field2 = 'brave world'
      doc.reload(:keep_ivars => true).should == doc
      doc.field2.should == 'world'
      doc.instance_eval { @some_ivar }.should == true
    end
  end

  context 'when the document is gone' do
    it 'raises when reloading' do
      SimpleDocument.delete_all
      expect {doc.reload }.to raise_error(NoBrainer::Error::DocumentNotFound)
    end
  end

  it 'destroys' do
    doc.destroy.should == true
    SimpleDocument.find(doc.id).should == nil
  end

  context "when the document already exists" do
    it 'raises an error when creating' do
      expect { SimpleDocument.create(:id => doc.id) }.to raise_error(NoBrainer::Error::DocumentNotSaved)
    end
  end
end

describe 'NoBrainer bulk inserts' do
  before { load_simple_document }

  context 'when using insert_all' do
    it 'inserts a bunch of documents' do
      keys = SimpleDocument.insert_all(100.times.map { |i| {:field1 => i+1} })
      SimpleDocument.where(:id => keys.first).count.should == 1
      SimpleDocument.count.should == 100
      SimpleDocument.where(:field1.gt 50).count.should == 50
    end
  end
end
