require 'spec_helper'

describe 'has_many_through' do
  before do
    define_class :Model1 do
      include NoBrainer::Document
      has_many :model2
      has_many :model3, :through => :model2
      has_many :model4, :through => :model3
    end
    define_class :Model2 do
      include NoBrainer::Document
      has_many :model3
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
    m2b = Model2.create(:model1 => m1)
    Model2.create(:model1 => m1) # noise
    m3a = Model3.create(:model2 => m2a)
    m3b = Model3.create(:model2 => m2b)
    Model4.create(:model3 => m3a)
    Model4.create(:model3 => m3b)
    Model4.create(:model3 => m3b)
  end

  it '#target_model' do
    Model1.association_metadata[:model2].target_model.should == Model2
    Model1.association_metadata[:model3].target_model.should == Model3
    Model1.association_metadata[:model4].target_model.should == Model4
  end

  context 'when going through the has_many' do
    it 'follow the association with eager loading' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(4).times
      Model1.first.model4.count.should == 3
    end

    it 'can be eager loaded' do
      m1 = Model1.preload(:model4).first
      NoBrainer.purge!
      m1.model4.count.should == 3
    end
  end

  context 'when going through the belongs_to' do
    it 'can be eager loaded' do
      m4s = Model4.preload(:model3 => { :model2 => :model1 }).to_a
      NoBrainer.purge!
      m4s.first.model3.model2.model1.should_not == nil
    end

    it 'can be eager loaded with criterias' do
      m4s = Model4.preload(:model3 => { :model2 => { :model1 => { :model4 => Model4.limit(2) } } }).to_a
      NoBrainer.purge!
      m4s.first.model3.model2.model1.model4.should == m4s[0...2]
    end
  end
end
