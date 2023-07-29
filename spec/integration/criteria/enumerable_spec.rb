# frozen_string_literal: true

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
          expect { SimpleDocument.all.map!(&:field1) }.to raise_error(/frozen/)
          expect { SimpleDocument.all << SimpleDocument.new }.to raise_error(/frozen/)
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

  context 'when using as_json' do
    let!(:documents) { 5.times.map { |i| SimpleDocument.create(:field1 => i) } }
    it 'enumerates first' do
      SimpleDocument.all.as_json.count.should == 5
      SimpleDocument.all.as_json(nil).count.should == 5
      SimpleDocument.all.as_json({}).count.should == 5

      JSON.parse(SimpleDocument.all.to_json).count.should == 5
    end
  end

  context 'when closing a stream' do
    before { SimpleDocument.insert_all(1000.times.map { {} }) }

    shared_examples_for 'streams' do
      it 'stops the stream' do
        iterations = 0
        iterator = criteria
        iterator.each do |x|
          iterations += 1
          iterator.close
        end
        iterations.should == 1
      end
    end

    context 'when using regular criteria' do
      let(:criteria) { SimpleDocument.all }
      it_behaves_like 'streams'
    end

    context 'when using raw criteria' do
      let(:criteria) { SimpleDocument.raw }
      it_behaves_like 'streams'
    end

    if ENV['EM'] == 'true'
      context 'when using raw changes' do
        let(:criteria) { SimpleDocument.raw.changes(:include_states => true) }
        it_behaves_like 'streams'
      end
    end
  end
end
