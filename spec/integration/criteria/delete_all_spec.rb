require 'spec_helper'

describe 'delete/destroy' do
  before { load_simple_document }
  let!(:docs) { 2.times.map { |i| SimpleDocument.create(:field1 => [i, i]) } }
  before { record_callbacks(SimpleDocument) }

  context 'when using delete_all' do
    it 'deletes documents' do
      SimpleDocument.delete_all
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.should == []
    end

    it 'returns the the number of deleted documents' do
      SimpleDocument.delete_all['deleted'].should == 2
    end

    context 'when using multi index' do
      before { SimpleDocument.index :field1, :multi => true }
      before { NoBrainer.sync_indexes }
      after  { NoBrainer.drop! }

      it 'deletes documents' do
        SimpleDocument.where(:field1.any => 1).delete_all
        SimpleDocument.count.should == 1
      end
    end
  end

  context 'when using destroy_all' do
    it 'destroys documents' do
      SimpleDocument.destroy_all
      SimpleDocument.count.should == 0
      SimpleDocument.callbacks.index(:before_destroy).should_not == nil
      SimpleDocument.callbacks.index(:after_destroy).should_not == nil
    end

    it 'returns the array of destroyed documents' do
      SimpleDocument.destroy_all.should =~ docs
    end
  end
end
