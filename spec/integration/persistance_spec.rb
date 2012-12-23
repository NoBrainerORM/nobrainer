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
end
