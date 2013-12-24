require 'spec_helper'

describe 'limit' do
  before { load_simple_document }

  let!(:docs) { 10.times.map { |i| SimpleDocument.create(:field1 => i) } }

  context 'when using limit' do
    it 'limits' do
      SimpleDocument.limit(3).count.should == 3
      SimpleDocument.limit(3).to_a.should == docs[0...3]
    end

    it 'skips' do
      SimpleDocument.skip(3).count.should == 7
      SimpleDocument.skip(3).to_a.should == docs[3...10]
    end

    it 'offsets' do
      SimpleDocument.offset(3).count.should == 7
      SimpleDocument.offset(3).to_a.should == docs[3...10]
    end

    it 'limit/skip' do
      SimpleDocument.offset(3).limit(3).count.should == 3
      SimpleDocument.offset(3).limit(3).to_a.should == docs[3...6]
    end
  end
end
