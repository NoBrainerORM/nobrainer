require 'spec_helper'

describe "all" do
  before { load_simple_document }
  before { 2.times { |i| SimpleDocument.create(:field1 => i) } }

  context 'when using all' do
    it 'returns all' do
      SimpleDocument.all.count.should == 2
    end
  end

  context 'when chaining all' do
    it 'returns all' do
      SimpleDocument.where(:field1 => 1).all.count.should == 1
      SimpleDocument.all.where(:field1 => 1).all.count.should == 1
      SimpleDocument.all.where(:field1 => 1).all.should be_a NoBrainer::Criteria
    end
  end
end
