require 'spec_helper'

describe NoBrainer do
  before { load_simple_document }

  let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

  it 'allows attribute access through []' do
    doc['field1'].should == 'hello'
    doc[:field1].should == 'hello'
  end

  it 'allows attribute update through []=' do
    doc['field2'] = 'brave world'
    doc['field2'].should == 'brave world'
    doc.field2.should == 'brave world'
    doc.attributes['field2'].should == 'brave world'
  end
end
