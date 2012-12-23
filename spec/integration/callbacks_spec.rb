require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_models }
  before { record_callbacks(BasicModel) }

  context 'with new models' do
    it 'fires the create and save callbacks' do
      doc = BasicModel.create
      BasicModel.callbacks[doc.id].should == [:create, :save]
    end
  end

  context 'with existing models' do
    it 'fires the update and save callbacks' do
      doc = BasicModel.create
      BasicModel.callbacks.clear

      doc.field1 = 'hello'
      doc.save
      BasicModel.callbacks[doc.id].should == [:update, :save]
    end
  end
end
