require 'spec_helper'

describe 'first_or_create' do
  before { load_simple_document }

  before { SimpleDocument.field :field1, :unique => true }
  let!(:existing_doc) { SimpleDocument.create(:field1 => 1) }

  context 'when the arguments are targeting an existing document' do
    it 'returns the document' do
      SimpleDocument.where(:field1 => 1).first_or_create.should == existing_doc
      SimpleDocument.count.should == 1
      SimpleDocument.where(:field1 => 2).first_or_create.should == SimpleDocument.last
      SimpleDocument.count.should == 2
    end
  end
end
