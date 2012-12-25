require 'spec_helper'

describe "primary key" do
  before { load_simple_document }

  it 'allows user-defined id' do
    SimpleDocument.create(:id => 1, :field1 => 'ohai')
    SimpleDocument.find(1).field1.should == 'ohai'
  end
end
