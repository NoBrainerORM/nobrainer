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
    end

    doc.reload
    doc.field1.should == 2
  end

  it 'destroys' do
    doc.destroy
    SimpleDocument.find(doc.id).should == nil
  end

  context "when the document already exists" do
    it 'raises an error when creating' do
      expect { SimpleDocument.create(:id => doc.id) }.to raise_error(NoBrainer::Error::DocumentNotSaved)
    end
  end

  context "when the document doesn't exist" do
    before { doc.destroy }

    it 'raises an error when updating' do
      expect { doc.update_attributes(:field1 => 'oops') }.to raise_error(NoBrainer::Error::DocumentNotSaved)
    end

    it 'raises an error when destroying' do
      expect { doc.destroy }.to raise_error(NoBrainer::Error::DocumentNotSaved)
    end
  end
end
