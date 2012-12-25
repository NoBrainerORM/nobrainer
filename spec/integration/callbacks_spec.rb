require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_models }
  before { record_callbacks(BasicModel) }

  context 'when no before_ callback returns false' do
    let!(:doc) { BasicModel.create(:field1 => 'hello', :field2 => 'world') }

    context 'when creating' do
      it 'fires the proper callbacks' do
        BasicModel.callbacks.should ==
          [:before_validation, :after_validation,
           :before_save, :before_create, :after_create, :after_save]
      end
    end

    context 'when updating' do
      it 'fires the proper callbacks' do
        BasicModel.callbacks.clear
        doc.update_attributes(:field1 => 'hello')
        BasicModel.callbacks.should == 
          [:before_validation, :after_validation,
           :before_save, :before_update, :after_update, :after_save]
      end
    end

    context 'when destroying' do
      it 'fires the proper callbacks' do
        BasicModel.callbacks.clear
        doc.destroy
        BasicModel.callbacks.should == [:before_destroy, :after_destroy]
      end
    end
  end

  context 'when a before_ callback returns false' do
    it 'halts create' do
      BasicModel.before_create { false }
      BasicModel.create(:field1 => 'hello').persisted?.should == false
    end

    it 'halts save' do
      BasicModel.before_save { new_record? }
      doc = BasicModel.create(:field1 => 'hello')
      doc.field1 = 'hi'
      doc.save
      doc.reload
      doc.field1.should == 'hello'
    end

    it 'halts updates' do
      BasicModel.before_update { new_record? }
      doc = BasicModel.create(:field1 => 'hello')
      doc.update_attributes(:field1 => 'hi')
      doc.reload
      doc.field1.should == 'hello'
    end

    it 'halts destroy' do
      BasicModel.before_destroy { false }
      doc = BasicModel.create(:field1 => 'hello')
      doc.destroy
      BasicModel.find(doc.id).should == doc
    end
  end
end
