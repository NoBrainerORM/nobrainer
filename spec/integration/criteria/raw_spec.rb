require 'spec_helper'

describe "raw" do
  before { load_simple_document }
  before { SimpleDocument.create }

  context 'when not using raw' do
    it 'returns the model' do
      SimpleDocument.all.first.should be_a SimpleDocument
      SimpleDocument.all.to_a.first.should be_a SimpleDocument
    end
  end

  context 'when using raw' do
    it 'returns the model' do
      SimpleDocument.all.raw.first.should be_a Hash
      SimpleDocument.all.raw.to_a.first.should be_a Hash
    end
  end
end
