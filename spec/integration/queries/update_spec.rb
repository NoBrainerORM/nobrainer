require 'spec_helper'

describe 'update' do
  before { load_simple_document }

  before { 2.times { SimpleDocument.create(:field1 => 10) } }

  context 'when passing a hash attribute' do
    it 'updates documents' do
      SimpleDocument.all.update(:field1 => 2)
      SimpleDocument.where(:field1 => 2).count.should == 2
    end
  end

  context 'when passing a block' do
    it 'updates documents' do
      # RethinkDB doesn't have a great syntax
      # We'll fix that later
      SimpleDocument.all.update do |doc|
        {:field1 => doc[:field1] * 2}
      end

      SimpleDocument.where(:field1 => 20).count.should == 2
    end
  end

  context 'when using the inc wrapper' do
    it 'increments a field' do
      SimpleDocument.all.inc(:field1)
      SimpleDocument.all.inc(:field1, 5)

      SimpleDocument.where(:field1 => 16).count.should == 2
    end
  end

  context 'when using the dec wrapper' do
    it 'decrements a field' do
      SimpleDocument.all.dec(:field1)
      SimpleDocument.all.dec(:field1, 5)

      SimpleDocument.where(:field1 => 4).count.should == 2
    end
  end
end
