require 'spec_helper'

describe "NoBrainer cache_key" do
  before { load_simple_document }
  let(:model_name) {doc.class.model_name.cache_key }
  let(:id) { doc.pk_value }

  context 'with a new record' do
    let(:doc) { SimpleDocument.new }
    it 'should append new' do
      doc.cache_key.should == "#{model_name}/new"
    end
  end

  context 'when not using timestamps' do
    let(:doc) { SimpleDocument.create }
    it 'should append id' do
      doc.cache_key.should == "#{model_name}/#{id}"
    end
  end

  context 'when using timestamps' do
    before { SimpleDocument.send(:include, NoBrainer::Document::Timestamps) }
    let(:time) { Time.now}
    let(:doc) { Timecop.freeze(time) { SimpleDocument.create }}
    let(:new_time) { Time.now}
    let(:touch!) { Timecop.freeze(new_time) { doc.update(:field1 => 'ohai') }}

    it 'should append id-timestamp on create' do
      timestamp = time.utc.to_s(:nsec)
      doc.cache_key.should == "#{model_name}/#{id}-#{timestamp}"
    end

    it 'should append a new id-timestamp on update' do
      old_timestamp = time.utc.to_s(:nsec)
      new_timestamp = new_time.utc.to_s(:nsec)
      touch!
      doc.cache_key.should_not == "#{model_name}/#{id}-#{old_timestamp}"
      doc.cache_key.should == "#{model_name}/#{id}-#{new_timestamp}"
    end
  end

end
