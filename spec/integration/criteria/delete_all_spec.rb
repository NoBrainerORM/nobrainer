require 'spec_helper'

describe 'delete/destroy' do
  before { load_simple_document }
  let!(:docs) { 2.times.map { SimpleDocument.create } }
  before { record_callbacks(SimpleDocument) }

  context 'when using delete_all' do
    it 'deletes documents' do
      SimpleDocument.delete_all
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.should == []
    end

    it 'returns the the number of deleted documents' do
      SimpleDocument.delete_all.should == 2
    end
  end

  context 'when using destroy_all' do
    it 'destroys documents' do
      SimpleDocument.destroy_all
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.should == [:before_destroy, :after_destroy] * 2
    end

    it 'returns the array of destroyed documents' do
      SimpleDocument.destroy_all.should == docs
    end
  end
end
