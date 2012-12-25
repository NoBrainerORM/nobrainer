require 'spec_helper'

describe "NoBrainer serialization" do
  before { load_models }

  let(:doc) { BasicModel.create(:field1 => 'hello') }

  it 'serializes to json' do
    JSON::parse(doc.to_json).should ==
      {'basic_model' => {'id' => doc.id, 'field1' => 'hello', 'field2' => nil}}
  end

  it 'serializes to xml' do
    # Not going to parse that crap
    doc.to_xml.should =~ /xml/
    doc.to_xml.should =~ /hello/
  end
end
