require 'spec_helper'

describe 'scope' do
  before { load_simple_document }

  let!(:doc1) { SimpleDocument.create(:field1 => 'ohai') }
  let!(:doc2) { SimpleDocument.create(:field1 => 'hello') }

  context 'when the scope is defined as a class method' do
    before do
      def SimpleDocument.haz_cheeseburger
        where(:field1 => 'ohai')
      end
    end

    it 'scopes' do
      SimpleDocument.haz_cheeseburger.count.should == 1
      SimpleDocument.all.haz_cheeseburger.count.should == 1
      SimpleDocument.all.should respond_to(:haz_cheeseburger)
    end
  end

  context 'when the scope is defined as a scope' do
    before do
      SimpleDocument.class_eval do
        scope :haz_cheeseburger, where(:field1 => 'ohai')
      end
    end

    it 'scopes' do
      SimpleDocument.haz_cheeseburger.count.should == 1
      SimpleDocument.all.haz_cheeseburger.count.should == 1
      SimpleDocument.all.should respond_to(:haz_cheeseburger)
    end
  end
end
