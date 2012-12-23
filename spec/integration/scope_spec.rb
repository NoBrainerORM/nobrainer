require 'spec_helper'

describe "NoBrainer scope" do
  before { load_models }

  context 'when the document does not exist' do
    it 'throws not found error' do
      expect { BasicModel.find('x') }.to raise_error(NoBrainer::Error::NotFound)
    end
  end
end
