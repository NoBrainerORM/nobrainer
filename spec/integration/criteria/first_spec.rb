require 'spec_helper'

describe 'first' do
  before { load_simple_document }

  context 'when there exist some docs' do
    let!(:docs) { 5.times.map { |i| SimpleDocument.create(:field1 => i) } }

    context 'when not using a scope' do
      describe 'first' do
        it 'returns the first document' do
          SimpleDocument.first.should == docs.first
        end
      end

      describe 'last' do
        it 'returns the last document' do
          SimpleDocument.last.should == docs.last
        end
      end

      describe 'sample' do
        it 'returns a random document' do
          docs = 10.times.map { SimpleDocument.sample }
          docs.first.should be_a(SimpleDocument)
          docs.uniq.size.should > 1
        end

        it 'returns an array of documents when supplied with an argument' do
          SimpleDocument.sample(1).should be_a(Array)
          SimpleDocument.sample(1).first.should be_a(SimpleDocument)

          SimpleDocument.sample(1).size.should == 1
          SimpleDocument.sample(2).size.should == 2
          SimpleDocument.sample(3).size.should == 3
        end
      end
    end

    context 'when using a scope' do
      describe 'first' do
        it 'returns the first document' do
          SimpleDocument.where(:field1 => 3).first.should == docs[3]
        end
      end

      describe 'last' do
        it 'returns the last document' do
          SimpleDocument.where(:field1 => 3).last.should == docs[3]
        end
      end
    end

    context 'when using an order_by scope' do
      context 'order_by is on the id' do
        describe 'first' do
          it 'returns the document' do
            SimpleDocument.all.order_by(SimpleDocument.pk_name => :desc).first.should == docs.last
          end
        end

        describe 'last' do
          it 'returns the document' do
            SimpleDocument.all.order_by(SimpleDocument.pk_name => :desc).last.should == docs.first
          end
        end
      end

      context 'order_by is not on the id' do
        describe 'first' do
          it 'returns the document' do
            SimpleDocument.all.order_by(:field1 => :desc).first.should == docs.last
          end
        end

        describe 'last' do
          it 'returns the document' do
            SimpleDocument.all.order_by(:field1 => :desc).last.should == docs.first
          end
        end
      end
    end
  end

  context 'when there are no docs' do
    describe 'first' do
      it 'returns nil' do
        SimpleDocument.first.should == nil
      end
    end

    describe 'last' do
      it 'returns nil' do
        SimpleDocument.last.should == nil
      end
    end
  end

  context 'when using polymorphism' do
    before { load_polymorphic_models }

    it 'returns the proper type' do
      Child.create
      Parent.first.class.should == Child
    end
  end

  context 'when using the bang version' do
    let!(:docs) { 2.times.map { |i| SimpleDocument.create(:field1 => i) } }

    it 'raises when the document is not present' do
      SimpleDocument.first!.should == docs.first
      SimpleDocument.last!.should == docs.last
      SimpleDocument.delete_all
      expect { SimpleDocument.first! }.to raise_error NoBrainer::Error::DocumentNotFound
      expect { SimpleDocument.last! }.to raise_error NoBrainer::Error::DocumentNotFound
    end
  end
end
