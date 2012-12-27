require 'spec_helper'

describe "each" do
  before { load_simple_document }

  context 'when there exist some documents' do
    let!(:documents) { 5.times.map { |i| SimpleDocument.create(:field1 => i) } }

    describe 'each' do
      it 'gets automatically called' do
        SimpleDocument.all.to_a.count.should == 5
      end

      it 'enumerate documents' do
        SimpleDocument.all.to_a.first.should be_kind_of SimpleDocument
      end

      it 'maps to documents' do
        SimpleDocument.all.map(&:field1).sort.should == (0..4).to_a
      end
    end
  end

  context 'when there are no documents' do
    describe 'each' do
      it 'gets automatically called' do
        SimpleDocument.all.to_a.count.should == 0
      end
    end
  end

  it 'proxies missing methods to enum' do
    SimpleDocument.all.should respond_to(:unshift)
  end
end
