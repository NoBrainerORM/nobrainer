require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }
  before { record_callbacks(SimpleDocument) }

  context 'when no before_ callback returns false' do
    let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

    context 'when creating' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.should ==
          [:before_validation, :after_validation,
           :before_save, :before_create, :after_create, :after_save]
      end
    end

    context 'when updating with update' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.update {{:field1 => 'hello'}}
        SimpleDocument.callbacks.should == [:before_update, :after_update]
      end
    end

    context 'when updating with save' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.update_attributes(:field1 => 'hello')
        SimpleDocument.callbacks.should == 
          [:before_validation, :after_validation,
           :before_save, :before_update, :after_update, :after_save]
      end
    end

    context 'when deleting' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.delete
        SimpleDocument.callbacks.should == []
      end
    end

    context 'when destroying' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.destroy
        SimpleDocument.callbacks.should == [:before_destroy, :after_destroy]
      end
    end
  end

  context 'when a before_ callback returns false' do
    it 'halts create' do
      SimpleDocument.before_create { false }
      SimpleDocument.create(:field1 => 'hello').persisted?.should == false
    end

    it 'halts save' do
      SimpleDocument.before_save { new_record? }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.field1 = 'hi'
      doc.save
      doc.reload
      doc.field1.should == 'hello'
    end

    it 'halts updates' do
      SimpleDocument.before_update { new_record? }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.update_attributes(:field1 => 'hi')
      doc.reload
      doc.field1.should == 'hello'
    end

    it 'halts destroy' do
      SimpleDocument.before_destroy { false }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.destroy
      SimpleDocument.find(doc.id).should == doc
    end
  end
end
