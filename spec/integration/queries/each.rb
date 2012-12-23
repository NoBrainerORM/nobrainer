require 'spec_helper'

describe "each" do
  before { load_models }

  context 'when there exist some documents' do
    let!(:models) { 5.times.map { |i| BasicModel.create(:field1 => i) } }

    describe 'each' do
      it 'gets automatically called' do
        BasicModel.all.to_a.count.should == 5
      end

      it 'enumerate models' do
        BasicModel.all.to_a.first.should be_kind_of BasicModel
      end

      it 'maps to models' do
        BasicModel.all.map(&:field1).sort.should == (0..4).to_a
      end
    end
  end

  context 'when there are no documents' do
    describe 'each' do
      it 'gets automatically called' do
        BasicModel.all.to_a.count.should == 0
      end
    end
  end
end
