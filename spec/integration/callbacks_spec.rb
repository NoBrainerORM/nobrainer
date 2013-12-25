require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }
  before { record_callbacks(SimpleDocument) }

  context 'when no before_ callback returns false' do
    let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

    context 'when creating' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.should ==
          [ :before_save, :before_create,
            :before_validation, :after_validation,
            :after_create, :after_save]
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
          [ :before_save, :before_update,
            :before_validation, :after_validation,
            :after_update, :after_save]
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
    it 'does not halt create' do
      SimpleDocument.before_create { false }
      SimpleDocument.create(:field1 => 'hello').persisted?.should == true
    end

    it 'does no halt save' do
      SimpleDocument.before_save { new_record? }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.field1 = 'hi'
      doc.save
      doc.reload
      doc.field1.should == 'hi'
    end

    it 'does not halt updates' do
      SimpleDocument.before_update { new_record? }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.update_attributes(:field1 => 'hi')
      doc.reload
      doc.field1.should == 'hi'
    end

    it 'does not halt destroy' do
      SimpleDocument.before_destroy { false }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.destroy
      SimpleDocument.find(doc.id).should == nil
    end
  end
end
