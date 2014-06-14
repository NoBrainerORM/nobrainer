require 'spec_helper'

describe "NoBrainer serialization" do
  before { load_simple_document }

  it 'serializes to json' do
    doc = SimpleDocument.create(:field1 => 'hello', :field2 => nil)
    JSON.parse(doc.to_json).should == {SimpleDocument.pk_name.to_s => doc.pk_value, 'field1' => 'hello', 'field2' => nil }
  end

  context 'without dynamic attributes' do
    it 'behaves properly in case of extra fields' do
      SimpleDocument.insert_all(:field1 => 'hello', :field_oops => 'oops')
      doc = SimpleDocument.first
      JSON.parse(doc.to_json).should == {SimpleDocument.pk_name.to_s => doc.pk_value, 'field1' => 'hello'}
    end
  end

  context 'with dynamic attributes' do
    before do
      SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
    end

    it 'behaves properly in case of extra fields' do
      SimpleDocument.insert_all(:field1 => 'hello', :field_oops => 'oops')
      doc = SimpleDocument.first
      JSON.parse(doc.to_json).should == {SimpleDocument.pk_name.to_s => doc.pk_value, 'field1' => 'hello', 'field_oops' => 'oops'}
    end
  end
end
