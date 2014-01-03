require 'spec_helper'

describe "NoBrainer timestamps" do
  context 'when using timestamps' do
    before { load_simple_document }
    # The default behavior is to always include timestamps
    let(:doc) { SimpleDocument.create }

    it 'populates the created_at/updated_at fields on creation' do
      time = Time.now
      Timecop.freeze(time) { SimpleDocument.create }

      SimpleDocument.first.created_at.to_i.should == time.to_i
      SimpleDocument.first.updated_at.to_i.should == time.to_i
    end

    it 'updates the updated_at field on updates, and not the created_at field' do
      old_time = Time.now
      new_time = 1.minute.from_now

      Timecop.freeze(old_time) { SimpleDocument.create }
      Timecop.freeze(new_time) { SimpleDocument.first.update_attributes!(:field1 => 'ohai') }

      SimpleDocument.first.created_at.to_i.should == old_time.to_i
      SimpleDocument.first.updated_at.to_i.should == new_time.to_i
    end
  end

  context 'when not using timestamps with disable_timestamps' do
    before { load_simple_document }
    before { SimpleDocument.disable_timestamps }

    it 'does not make any created_at/updated_at fields visible' do
      expect { SimpleDocument.new.created_at }.to raise_error NoMethodError
      expect { SimpleDocument.new.updated_at }.to raise_error NoMethodError
      expect { SimpleDocument.create }.not_to raise_error
    end
  end
end
