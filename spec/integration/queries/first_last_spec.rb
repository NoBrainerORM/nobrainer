require 'spec_helper'

describe "first and last" do
  before { load_models }

  context 'when there exist some documents' do
    let!(:models) { 5.times.map { |i| BasicModel.create(:field1 => i) } }

    context 'when not using a scope' do
      describe 'first' do
        it 'returns the first document', :pending => 'need created_at field' do
          BasicModel.first.id.should == models.first.id
        end
      end

      describe 'last' do
        it 'returns the last document', :pending => 'need created_at field' do
          BasicModel.last.id.should == models.last.id
        end
      end
    end

    context 'when using a scope' do
      describe 'first' do
        it 'returns the document' do
          BasicModel.where(:field1 => 3).first.id.should == models[3].id
        end
      end

      describe 'last' do
        it 'returns the document' do
          BasicModel.where(:field1 => 4).last.id.should == models[4].id
        end
      end
    end
  end

  context 'when there are no documents' do
    describe 'first' do
      it 'returns nil' do
        BasicModel.first.should == nil
      end
    end

    describe 'last' do
      it 'returns nil' do
        BasicModel.last.should == nil
      end
    end
  end
end
