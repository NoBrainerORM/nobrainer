require 'spec_helper'

describe "NoBrainer query runner" do
  before { load_simple_document }
  before { SimpleDocument.create }

  describe 'run' do
    it 'run takes an argument' do
      NoBrainer.run(SimpleDocument.to_rql.count).should == 1
    end

    it 'run takes a block with r as an argument' do
      NoBrainer.run { |r| r.table('simple_documents').count }.should == 1
    end
  end
end
