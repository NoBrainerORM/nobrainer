require 'spec_helper'

describe 'delete/destroy' do
  before { load_simple_document }
  let!(:docs) { 2.times.map { SimpleDocument.create } }
  before { record_callbacks(SimpleDocument) }

  context 'when using delete' do
    it 'deletes documents' do
      SimpleDocument.delete_all.should == 2
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.should == []
    end
  end

  context 'when passing a block' do
    it 'destroys documents' do
      SimpleDocument.destroy_all.should == docs
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.should == [:before_destroy, :after_destroy] * 2
    end
  end
end
