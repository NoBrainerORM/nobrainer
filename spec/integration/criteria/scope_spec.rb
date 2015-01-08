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

  context 'when using multiple default scopes' do
    before { load_polymorphic_models }

    before do
      Parent.class_eval do
        field :field1
        field :field2
        field :field3
        default_scope { where(:field1 => 1) }
        default_scope { order_by(:field3) }
      end
      Child.class_eval do
        default_scope { where(:field2 => 1) }
        default_scope { order_by(:field3 => :desc) } # latest order_by wins
      end
    end

      let!(:doc1) { Child.create(:field1 => 1, :field2 => 1, :field3 => 3) }
      let!(:doc2) { Child.create(:field1 => 1, :field2 => 1, :field3 => 1) }
      let!(:doc3) { Child.create(:field1 => 1, :field2 => 1, :field3 => 2) }
      let!(:doc4) { Child.create(:field1 => 2, :field2 => 1, :field3 => 5) }
      let!(:doc5) { Child.create(:field1 => 1, :field2 => 2, :field3 => 4) }

    it 'applies the scopes in the proper order' do
      Parent.to_a.should == [doc2, doc3, doc1, doc5]
      Child.to_a.should == [doc1, doc3, doc2]
    end
  end
end
