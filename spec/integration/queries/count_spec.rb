require 'spec_helper'

describe "count" do
  before { load_models }

  context 'when the table does not exist yet' do
    it 'returns 0' do
      BasicModel.count.should == 0
    end
  end

  context 'when unscoped' do
    it 'returns the number of documents' do
      BasicModel.create
      BasicModel.count.should == 1
      BasicModel.create
      BasicModel.count.should == 2
    end
  end

  context 'when scoped' do
    it 'returns the number of documents' do
      BasicModel.create(:field1 => 'ohai')
      BasicModel.create(:field1 => 'ohai')
      BasicModel.create(:field1 => 'hello')

      BasicModel.where(:field1 => 'ohai').count.should == 2
    end
  end
end
