require 'spec_helper'

describe "#cache_key" do
  before { load_simple_document }
  let(:table_name) { SimpleDocument.table_name }
  let(:doc) { SimpleDocument.create }

  context 'when not using timestamps' do
    it "should be table_name/id" do
      doc.cache_key.should == "#{table_name}/#{doc.pk_value}"
    end
  end

  context 'when using timestamps' do
    before { SimpleDocument.send(:include, NoBrainer::Document::Timestamps) }

    context 'when using an existing document' do
      it "should be table_name/id-timestamp" do
        doc.cache_key.should == "#{table_name}/#{doc.pk_value}-#{doc.updated_at.strftime("%s%L")}"
      end

      context 'when updating the document' do
        it "should change" do
          orig_cache_key = doc.cache_key
          Timecop.freeze(doc.updated_at + 1) { doc.update(:field1 => 123) }
          doc.cache_key.should_not == orig_cache_key
        end
      end
    end

    context 'when using a new document' do
      let(:doc) { SimpleDocument.new }

      it "should not contain timestamps" do
        doc.cache_key.should == "#{table_name}/#{doc.pk_value}"
      end
    end
  end
end
