require 'spec_helper'

describe 'NoBrainer dirty' do
  before { load_simple_document }

  it 'tracks attribute changes' do
    doc = SimpleDocument.new(:field1 => 'hello')
    doc.save

    doc.changed?.should == false
    doc.changed.should == []
    doc.changes.should == {}

    doc.field1_changed?.should == false
    doc.field1_change.should == nil
    doc.field1_was.should == 'hello'

    doc.field2_changed?.should == false
    doc.field2_change.should == nil
    doc.field2_was.should == nil

    doc.field3_changed?.should == false
    doc.field3_change.should == nil
    doc.field3_was.should == nil

    doc.field1 = 'ohai'
    doc.field2 = 'yay'

    doc.changed?.should == true
    doc.changed.should == ['field1', 'field2']
    doc.changes.should == {'field1' => ['hello', 'ohai'], 'field2' => [nil, 'yay']}

    doc.field1_changed?.should == true
    doc.field1_change.should == ['hello', 'ohai']
    doc.field1_was.should == 'hello'

    doc.field2_changed?.should == true
    doc.field2_change.should == [nil, 'yay']
    doc.field2_was.should == nil

    doc.field3_changed?.should == false
    doc.field3_change.should == nil
    doc.field3_was.should == nil

    doc.save

    doc.changed?.should == false
    doc.changed.should == []
    doc.changes.should == {}

    doc.field1_changed?.should == false
    doc.field1_change.should == nil
    doc.field1_was.should == 'ohai'

    doc.field2_changed?.should == false
    doc.field2_change.should == nil
    doc.field2_was.should == 'yay'

    doc.field3_changed?.should == false
    doc.field3_change.should == nil
    doc.field3_was.should == nil

    doc = SimpleDocument.first
    doc.changed?.should == false

    doc.field1 = 'hello'
    doc.changed?.should == true
    doc.reload
    doc.changed?.should == false
  end

  context 'when using defaults' do
    before { SimpleDocument.field :field1, :default => ->{ 'hello' } }

    it 'shows the default value as changed' do
      doc = SimpleDocument.new
      doc.changed?.should == true
      doc.field1_change.should == [nil, 'hello']
      doc.save
      doc.changed?.should == false
    end
  end

  context 'when using hashes' do
    it 'tracks changes' do
      doc = SimpleDocument.create(:field1 => {})
      doc.field1['key'] = 'hello'
      doc.field1_change.should == [{}, {'key' => 'hello'}]
    end
  end

  context 'when using arrays' do
    it 'tracks changes' do
      doc = SimpleDocument.create(:field1 => [])
      doc.field1 << 'hello'
      doc.field1_change.should == [[], ['hello']]
    end
  end

  context 'when using the attributes getter' do
    it 'tracks changes' do
      doc = SimpleDocument.create(:field1 => {})
      doc.attributes['field1']['key'] = 'hello'
      doc.field1_change.should == [{}, {'key' => 'hello'}]
    end
  end

  context 'when nothing changes really' do
    it 'tracks changes' do
      doc = SimpleDocument.create(:field1 => 'hi')
      doc.field1 = 'hi'
      doc.changed?.should == false
      doc.field1_changed?.should == false
    end
  end

  context 'when changing from undefined to nil' do
    it 'tracks changes' do
      doc = SimpleDocument.create
      doc.field1 = nil
      doc.changed?.should == true
      doc.field1_change.should == [nil, nil]
    end
  end

  context 'when reloading' do
    it 'tracks changes' do
      doc = SimpleDocument.create(:field1 => 'ohai')
      doc.reload
      doc.field1 = 'ohai'
      doc.changed?.should == false
    end
  end

  context 'when using dynamic attributes' do
    it 'track changes' do
      SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
      doc = SimpleDocument.create(:hello => {})
      doc.changed?.should == false
      doc.changes.should == {}
      doc['hello']['xx'] = 123
      doc.changed?.should == true
      doc.save
      doc.changed?.should == false
      doc['yay'] = 123
      doc.changed?.should == true
    end
  end
end
