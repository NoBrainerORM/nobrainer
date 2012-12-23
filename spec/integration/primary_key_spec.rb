require 'spec_helper'

describe "primary key" do
  before { load_models }

  it 'allows user-defined id' do
    BasicModel.create(:id => 1, :field1 => 'ohai')
    BasicModel.find(1).field1.should == 'ohai'
  end
end
