require 'spec_helper'

describe "NoBrainer timestamps" do
  context 'when using timestamps' do
    before { load_simple_document }
    before { SimpleDocument.send(:include, NoBrainer::Document::Timestamps) }
    let(:doc) { SimpleDocument.create }

    it 'populates the created_at/updated_at fields on creation' do
      time = Time.now
      Timecop.freeze(time) { SimpleDocument.create }

      SimpleDocument.first.created_at.to_i.should == time.to_i
      SimpleDocument.first.updated_at.to_i.should == time.to_i
    end

    it 'updates the updated_at field on updates, and not the created_at field' do
      old_time = Time.now
      new_time = old_time + 60

      Timecop.freeze(old_time) { SimpleDocument.create }
      Timecop.freeze(new_time) { SimpleDocument.first.update_attributes!(:field1 => 'ohai') }

      SimpleDocument.first.created_at.to_i.should == old_time.to_i
      SimpleDocument.first.updated_at.to_i.should == new_time.to_i
    end
  end

  context 'when not using timestamps' do
    before { load_simple_document }

    it 'does not make any created_at/updated_at fields' do
      expect { SimpleDocument.new.created_at }.to raise_error NoMethodError
      expect { SimpleDocument.new.updated_at }.to raise_error NoMethodError
    end
  end

  context 'when using the shorthand module' do
    before do
      define_constant :SimpleDocument do
        include NoBrainer::DocumentWithTimestamps
      end
    end

    it 'populates the created_at/updated_at fields on creation' do
      time = Time.now
      Timecop.freeze(time) { SimpleDocument.create }

      SimpleDocument.first.created_at.to_i.should == time.to_i
      SimpleDocument.first.updated_at.to_i.should == time.to_i
    end
  end
end
