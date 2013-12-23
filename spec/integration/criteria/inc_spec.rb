require 'spec_helper'

describe 'inc/dec' do
  before { load_simple_document }

  let!(:docs) { 2.times { SimpleDocument.create(:field1 => 10) } }

  context 'when using a selection' do
    context 'when using the inc wrapper' do
      it 'increments a field' do
        SimpleDocument.inc_all(:field1)
        SimpleDocument.inc_all(:field1, 5)

        SimpleDocument.where(:field1 => 16).count.should == 2
      end
    end

    context 'when using the dec wrapper' do
      it 'decrements a field' do
        SimpleDocument.dec_all(:field1)
        SimpleDocument.dec_all(:field1, 5)

        SimpleDocument.where(:field1 => 4).count.should == 2
      end
    end
  end

  # TODO. We don't want to do the update right away. we want
  # to defer it until we save.
  context 'when using a document'
end
