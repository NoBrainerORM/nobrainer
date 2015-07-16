require 'spec_helper'

describe "NoBrainer timestamps" do
  context 'when using timestamps' do
    before { load_simple_document }
    before { SimpleDocument.send(:include, NoBrainer::Document::Timestamps) }

    let(:now)    { Time.now }
    let(:past)   { now - 30 }
    let(:future) { now + 30 }

    it 'populates the created_at/updated_at fields on creation' do
      Timecop.freeze(now) { SimpleDocument.create }

      SimpleDocument.first.created_at.to_i.should == now.to_i
      SimpleDocument.first.updated_at.to_i.should == now.to_i
    end

    it 'updates the updated_at field on updates, and not the created_at field' do
      Timecop.freeze(now) { SimpleDocument.create }
      Timecop.freeze(future) { SimpleDocument.first.update(:field1 => 'ohai') }

      SimpleDocument.first.created_at.to_i.should == now.to_i
      SimpleDocument.first.updated_at.to_i.should == future.to_i
    end

    it 'allows overriding created_at' do
      Timecop.freeze(now) { SimpleDocument.create(:created_at => past) }
      SimpleDocument.first.created_at.to_i.should == past.to_i
      SimpleDocument.first.updated_at.to_i.should == now.to_i

      SimpleDocument.first.update(:created_at => past)
      SimpleDocument.first.created_at.to_i.should == past.to_i
    end

    it 'allows overriding updated_at' do
      Timecop.freeze(now) { SimpleDocument.create(:updated_at => past) }
      SimpleDocument.first.created_at.to_i.should == now.to_i
      SimpleDocument.first.updated_at.to_i.should == past.to_i

      SimpleDocument.first.update(:updated_at => past)
      SimpleDocument.first.updated_at.to_i.should == past.to_i
    end

    describe '#touch' do
      it 'updates the updated_at field' do
        Timecop.freeze(now) { SimpleDocument.create }
        Timecop.freeze(future) { SimpleDocument.first.touch }

        SimpleDocument.first.created_at.to_i.should == now.to_i
        SimpleDocument.first.updated_at.to_i.should == future.to_i
      end

      it 'raises if there are some validations errors' do
        doc = SimpleDocument.create
        doc.created_at = 'bla bla'
        expect { doc.touch }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end
  end

  context 'when not using timestamps' do
    before { load_simple_document }

    it 'does not make any created_at/updated_at fields' do
      expect { SimpleDocument.new.created_at }.to raise_error NoMethodError
      expect { SimpleDocument.new.updated_at }.to raise_error NoMethodError
    end

    it 'does not provide touch' do
      expect { SimpleDocument.new.touch }.to raise_error NoMethodError
    end
  end
end
