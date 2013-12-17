require 'spec_helper'

describe 'NoBrainer dirty' do
  before { load_simple_document }
  before { SimpleDocument.disable_timestamps }

  it 'tracks attribute changes' do
    doc = SimpleDocument.create(:field1 => 'hello')

    doc.changed?.should == false
    doc.changed.should == []
    doc.changes.should == {}
    doc.changed_attributes.should == {}

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
    doc.field3 = nil

    doc.changed?.should == true
    doc.changed.should == [:field1, :field2]
    doc.changes.should == {:field1 => ['hello', 'ohai'], :field2 => [nil, 'yay']}
    doc.changed_attributes.should == {:field1 => 'hello', :field2 => nil}

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
    doc.previous_changes.should == {:field1 => ['hello', 'ohai'], :field2 => [nil, 'yay']}
    doc.changed_attributes.should == {}

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
end
