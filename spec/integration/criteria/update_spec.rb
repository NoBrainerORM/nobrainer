require 'spec_helper'

describe 'update' do
  before { load_simple_document }

  before { 2.times { SimpleDocument.create(:field1 => 10) } }

  context 'when passing a hash of attributes' do
    it 'updates documents' do
      SimpleDocument.update_all(:field1 => 2)
      SimpleDocument.where(:field1 => 2).count.should == 2
    end
  end

  context 'when passing a block' do
    it 'updates documents' do
      # RethinkDB doesn't have a great syntax
      # We'll fix that later
      SimpleDocument.update_all do |doc|
        {:field1 => doc[:field1] * 2}
      end

      SimpleDocument.where(:field1 => 20).count.should == 2
    end
  end
end
