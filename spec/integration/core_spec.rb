require 'spec_helper'

describe 'Model loader' do
  it 'prevents the same model to be loaded twice' do
    NoBrainer::Document.all.should == []

    define_class :Post do
      include NoBrainer::Document
    end

    NoBrainer::Document.all.should == [Post]

    Object.send(:remove_const, :Post)
    @defined_constants = {}

    expect do
      define_class :Post do
        include NoBrainer::Document
      end
    end.to raise_error(/The model `Post' is already registered/)
  end
end
