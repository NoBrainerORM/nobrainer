require 'spec_helper'

describe "NoBrainer serialization" do
  before { load_simple_document }
  before { SimpleDocument.disable_timestamps }

  let(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => nil) }

  it 'serializes to json' do
    # field3 remains unset.
    JSON::parse(doc.to_json).should == {'id' => doc.id, 'field1' => 'hello', 'field2' => nil }
  end
end
