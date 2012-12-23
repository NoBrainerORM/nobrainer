require 'spec_helper'

describe 'NoBrainer persistance' do
  before { load_models }

  let!(:doc) { BasicModel.create(:field1 => 'hello', :field2 => 'world') }

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

  it 'updates with update_attribute' do
    doc.update_attribute(:field1, 'ohai')
    doc.reload
    doc.field1.should == 'ohai'
  end

  it 'destroys' do
    doc.destroy
    expect { BasicModel.find(doc.id) }.to raise_error(NoBrainer::Error::NotFound)
  end

  context "when the document already exists" do
    it 'raises an error when creating' do
      expect { BasicModel.create(:id => doc.id) }.to raise_error(NoBrainer::Error::Write)
    end
  end

  context "when the document doesn't exist" do
    before { doc.destroy }

    it 'raises an error when updating' do
      expect { doc.update_attributes(:field1 => 'oops') }.to raise_error(NoBrainer::Error::Write)
    end

    it 'raises an error when destroying' do
      expect { doc.destroy }.to raise_error(NoBrainer::Error::Write)
    end
  end
end
