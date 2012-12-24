require 'spec_helper'

describe "NoBrainer selection" do
  before { load_models }

  context 'when the document does not exist' do
    describe 'find' do
      it 'returns nil' do
        BasicModel.find('x').should == nil
      end
    end

    describe 'find!' do
      it 'throws not found error' do
        expect { BasicModel.find!('x') }.to raise_error(NoBrainer::Error::NotFound)
      end
    end
  end
end
