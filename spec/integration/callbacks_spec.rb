require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_models }
  before { record_callbacks(BasicModel) }

  let!(:doc) { BasicModel.create(:field1 => 'hello', :field2 => 'world') }

  context 'when creating' do
    it 'fires the create and save callbacks' do
      BasicModel.callbacks[doc.id].should == [:create, :save]
    end
  end

  context 'when updating' do
    it 'fires the update and save callbacks' do
      BasicModel.callbacks.clear
      doc.update_attributes(:field1 => 'hello')
      BasicModel.callbacks[doc.id].should == [:update, :save]
    end
  end

  context 'when destroying' do
    it 'fires the destroy callback' do
      BasicModel.callbacks.clear
      doc.destroy
      BasicModel.callbacks[doc.id].should == [:destroy]
    end
  end
end
