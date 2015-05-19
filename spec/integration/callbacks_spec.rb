require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }
  before { record_callbacks(SimpleDocument) }

  context 'when no before_ callback returns false' do
    let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

    context 'when creating' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.should ==
          [ :before_initialize, :after_initialize,
            :before_validation, :after_validation,
            :before_save, :before_create,
            :after_create, :after_save]
      end
    end

    context 'when updating with save' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.update(:field1 => 'hi')
        SimpleDocument.callbacks.should ==
          [ :before_validation, :after_validation,
            :before_save, :before_update,
            :after_update, :after_save]
      end
    end

    context 'when updating with save, but nothing changed' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.update(:field1 => 'hello')
        SimpleDocument.callbacks.should ==
          [ :before_validation, :after_validation,
            :before_save, :before_update,
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

    context 'when reloading' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        doc.reload
        SimpleDocument.callbacks.should == [:before_initialize, :after_initialize]
      end
    end

    context 'when finding' do
      it 'fires the proper callbacks' do
        SimpleDocument.callbacks.clear
        SimpleDocument.each { }
        SimpleDocument.callbacks.should == [:before_initialize, :after_initialize, :after_find]
        SimpleDocument.callbacks.clear
        SimpleDocument.find(doc.pk_value)
        SimpleDocument.callbacks.should == [:before_initialize, :after_initialize, :after_find]
      end
    end
  end

  context 'when validation fails on create' do
    it 'does not call the after callbacks' do
      SimpleDocument.after_create { raise "oh no" }
      SimpleDocument.validates_presence_of :field1
      expect { SimpleDocument.create! }.to raise_error NoBrainer::Error::DocumentInvalid
    end
  end

  context 'when validation fails on update' do
    it 'does not call the after callbacks' do
      SimpleDocument.after_update { raise "oh no" }
      SimpleDocument.validates_presence_of :field1
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.update?(:field1 => nil).should == false
    end
  end

  context 'when validation fails on save' do
    it 'does not call the after callbacks' do
      SimpleDocument.validates_presence_of :field1
      doc = SimpleDocument.create(:field1 => 'hello')
      SimpleDocument.after_save { raise "oh no" }
      doc.update?(:field1 => nil).should == false
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
      doc.update(:field1 => 'hi')
      doc.reload
      doc.field1.should == 'hi'
    end

    it 'does not halt destroy' do
      SimpleDocument.before_destroy { false }
      doc = SimpleDocument.create(:field1 => 'hello')
      doc.destroy
      SimpleDocument.find?(doc.pk_value).should == nil
    end

    it 'does not halt validations' do
      SimpleDocument.before_validation { false }
      SimpleDocument.new.valid?.should == true
    end
  end
end
