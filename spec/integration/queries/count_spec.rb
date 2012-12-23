require 'spec_helper'

describe "count" do
  before { load_models }

  context 'when the table does not exist yet' do
    it 'returns 0' do
      BasicModel.count.should == 0
    end
  end

  it 'returns the number of documents' do
    BasicModel.create
    BasicModel.count.should == 1
    BasicModel.create
    BasicModel.count.should == 2
  end
end
