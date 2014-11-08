require 'spec_helper'

describe 'has_one' do
  before do
    define_class :User do
      include NoBrainer::Document
      has_one :address
    end

    define_class :Address do
      include NoBrainer::Document
      belongs_to :user
    end
  end

  it 'behaves like a has_many, but singularized' do
    user = User.create
    User.first.address.should == nil
    Address.create(:user => user)
    User.first.address.should == Address.first
  end
end
