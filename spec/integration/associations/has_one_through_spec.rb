require 'spec_helper'

describe 'has_many_through' do
  before do
    define_class :Model1 do
      include NoBrainer::Document
      has_many :model2
      has_one :model3, :through => :model2
      has_many :model4, :through => :model3
    end
    define_class :Model2 do
      include NoBrainer::Document
      has_one :model3
      belongs_to :model1
    end
    define_class :Model3 do
      include NoBrainer::Document
      has_many :model4
      belongs_to :model2
    end
    define_class :Model4 do
      include NoBrainer::Document
      belongs_to :model3
    end
  end

  before do
    m1 = Model1.create
    m2a = Model2.create(:model1 => m1)
    m3a = Model3.create(:model2 => m2a)
    Model4.create(:model3 => m3a)
  end

  context 'when going through the has_many' do
    it 'follow the association with eager loading' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(4).times
      Model1.first.model4.count.should == 1
    end

    it 'can be eager loaded' do
      m1 = Model1.preload(:model3).first
      m3 = Model3.first
      NoBrainer.purge!
      m1.model3.should == m3
    end
  end
end
