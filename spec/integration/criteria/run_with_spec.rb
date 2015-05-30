require 'spec_helper'

describe 'run_with' do
  before { load_simple_document }

  it 'runs the query with options' do
    SimpleDocument.run_with(:profile => true).raw.first.to_a.first.should == 'profile'
  end

  it 'override NoBrainer.run_with' do
    NoBrainer.run_with(:profile => true) do
      SimpleDocument.run_with(:profile => false).raw.first.to_a.first.should_not == 'profile'
    end
  end
end
