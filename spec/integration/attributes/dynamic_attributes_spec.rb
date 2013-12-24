require 'spec_helper'

describe 'NoBrainer::Document::DynamicAttributes' do
  before do
    load_simple_document
    SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
  end

  let!(:doc) { SimpleDocument.create(dynamic_field1: 'hello') }

  it 'allows dynamic attribute access through []' do
    doc['dynamic_field1'].should == 'hello'
    doc[:dynamic_field1].should == 'hello'
  end

  it 'allows attribute update through []=' do
    doc['dynamic_field2'] = 'world'
    doc['dynamic_field2'].should == 'world'
    doc.attributes['dynamic_field2'].should == 'world'
  end

  it 'persists dynamic attributes' do
    doc['dynamic_field2'] = 'world'
    doc.save
    doc.reload
    doc['dynamic_field2'].should == 'world'
  end

  it 'tracks dynamic attributes' do
    doc['dynamic_field'] = 'hello'
    doc.changes.should == {'dynamic_field' => [nil, 'hello']}
    doc.save
    doc['dynamic_field'] = 'world'
    doc.changes.should == {'dynamic_field' => ['hello', 'world']}
  end
end
