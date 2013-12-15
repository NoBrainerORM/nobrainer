require 'spec_helper'

describe "count" do
  before { load_simple_document }

  context 'when the table does not exist yet' do
    it 'returns 0' do
      SimpleDocument.count.should == 0
    end
  end

  context 'when unscoped' do
    it 'returns the number of documents' do
      SimpleDocument.create
      SimpleDocument.count.should == 1
      SimpleDocument.create
      SimpleDocument.count.should == 2
    end
  end

  context 'when scoped' do
    it 'returns the number of documents' do
      SimpleDocument.create(:field1 => 'ohai')
      SimpleDocument.create(:field1 => 'ohai')
      SimpleDocument.create(:field1 => 'hello')

      SimpleDocument.where(:field1 => 'ohai').count.should == 2
    end
  end

  context 'when using polymorphism' do
    before { load_polymorphic_models }

    it 'counts the proper types' do
      Parent.create
      Child.create
      GrandChild.create
      Parent.count.should == 3
      Child.count.should == 2
      GrandChild.count.should == 1
    end
  end
end

describe "any?" do
  before { load_simple_document }

  it 'returns whether some document exists' do
    SimpleDocument.create(:field1 => 'ohai')
    SimpleDocument.create(:field1 => 'ohai')
    SimpleDocument.create(:field1 => 'hello')

    SimpleDocument.all.any?.should == true
    SimpleDocument.all.any? { |doc| doc.field1 == 'nop' }.should == false
    SimpleDocument.all.any? { |doc| doc.field1 == 'hello' }.should == true
  end
end
