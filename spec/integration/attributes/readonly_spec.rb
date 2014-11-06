require 'spec_helper'

describe 'read only fields' do
  before { load_simple_document }

  context 'when trying to assign a readonly field' do
    it 'raises' do
      SimpleDocument.field :field1, :readonly => true
      doc = SimpleDocument.create(:field1 => 'hello')
      expect { doc.update(:field1 => 'ohno') }.to raise_error(NoBrainer::Error::ReadonlyField)
      expect { doc.update(SimpleDocument.pk_name => 'ohno') }.to raise_error(NoBrainer::Error::ReadonlyField)
    end
  end
end
