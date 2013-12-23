require 'spec_helper'

describe NoBrainer do
  before { load_simple_document }

  let(:doc) { SimpleDocument.create }

  it 'saves hashes properly' do
    doc.field1 = {'hello' => 'world'}
    doc.save
    doc.field1 = {'ohai' => ':)'}
    doc.save
    doc.reload
    doc.field1.should == {'ohai' => ':)'}
  end
end
