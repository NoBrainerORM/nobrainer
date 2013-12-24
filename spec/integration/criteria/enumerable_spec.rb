require 'spec_helper'

describe "each" do
  before { load_simple_document }

  context 'when there exist some documents' do
    let!(:documents) { 5.times.map { |i| SimpleDocument.create(:field1 => i) } }

    describe 'each' do
      it 'returns self' do
        SimpleDocument.all.each { }.to_a.should == documents
      end

      it 'gets automatically called' do
        SimpleDocument.all.each.to_a.size == 5
      end

      it 'gets automatically called' do
        SimpleDocument.all.count.should == 5
        SimpleDocument.all.size.should == 5
      end

      it 'enumerate documents' do
        SimpleDocument.all.first.should be_kind_of SimpleDocument
      end

      it 'maps to documents' do
        SimpleDocument.all.map(&:field1).sort.should == (0..4).to_a
      end

      context 'when trying to modify the criteria array' do
        it 'raises' do
          expect { SimpleDocument.all.map!(&:field1) }.to raise_error
          expect { SimpleDocument.all << SimpleDocument.new }.to raise_error
        end
      end
    end
  end

  context 'when using ==' do
    let!(:documents) { 2.times.map { |i| SimpleDocument.create(:field1 => i) } }

    context 'when comparing criteria' do
      it 'uses the regular behavior' do
        SimpleDocument.all.should_not == SimpleDocument.all.limit(100)
      end
    end

    context 'when comparing to an enumerable' do
      it 'casts to array' do
        SimpleDocument.all.should == documents
      end
    end

    context 'when comparing to some random stuff' do
      it 'casts to array' do
        SimpleDocument.all.should_not == "hello"
      end
    end
  end

  context 'when there are no documents' do
    describe 'each' do
      it 'gets automatically called' do
        SimpleDocument.all.count.should == 0
        SimpleDocument.all.size.should == 0
      end
    end
  end

  context 'when using polymorphism' do
    before { load_polymorphic_models }

    it 'returns the proper instance types' do
      Parent.create
      Child.create
      Parent.all.to_a.map(&:class).should =~ [Parent, Child]
      Child.all.to_a.map(&:class).should =~ [Child]
    end
  end

  it 'proxies missing methods to enum' do
    SimpleDocument.all.should respond_to(:unshift)
  end
end
