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
end
