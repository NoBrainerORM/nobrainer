require 'spec_helper'

describe 'scope' do
  before { load_simple_document }

  context 'when using a single scope' do
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

    context 'when the scope is defined as a lambda' do
      before do
        SimpleDocument.class_eval do
          scope :haz_cheeseburger, ->(name){ where(:field1 => name) }
        end
      end

      it 'scopes' do
        SimpleDocument.haz_cheeseburger('ohai').count.should == 1
        SimpleDocument.all.haz_cheeseburger('ohai').count.should == 1
        SimpleDocument.all.should respond_to(:haz_cheeseburger)
      end
    end
  end

  context 'when chaining scopes' do
    let!(:doc1) { SimpleDocument.create(:field1 => 'hello', :field2 => 'xxx') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'xxx',   :field2 => 'world') }
    let!(:doc3) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

    before do
      SimpleDocument.class_eval do
        scope :s1, where(:field1 => 'hello')
        scope :s2, where(:field2 => 'world')
      end
    end

    it 'scopes' do
      SimpleDocument.s1.s2.count.should == 1
      SimpleDocument.s1.s2.first.pk_value.should == doc3.pk_value
    end
  end

  context 'when using a default scope' do
    let!(:doc1) { SimpleDocument.create(:field1 => 'ohai') }
    let!(:doc2) { SimpleDocument.create(:field1 => 'hello') }

    before do
      SimpleDocument.class_eval do
        default_scope where(:field1 => 'ohai')
      end
    end

    context 'when using find()' do
      it 'does not apply the default scope' do
        SimpleDocument.find(doc2.pk_value).should == doc2
      end
    end

    context 'when doing regular queries' do
      it 'applies the default scope' do
        SimpleDocument.count.should == 1
      end
    end

    context 'when doing scoped queries' do
      it 'applies the default scope' do
        SimpleDocument.scoped.count.should == 1
      end
    end

    context 'when doing unscoped queries' do
      it 'does not apply the default scope' do
        SimpleDocument.unscoped.count.should == 2
      end
    end

    context 'when forcing scoped queries' do
      it 'applies the default scope' do
        SimpleDocument.unscoped.scoped.count.should == 1
      end
    end
  end
end
