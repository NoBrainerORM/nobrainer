require 'spec_helper'

describe 'cache' do
  before { load_simple_document }

  let!(:docs) { 2.times.map { |i| SimpleDocument.create(:field1 => i) } }

  context 'when using the cache' do
    it 'uses the cache' do
      criteria = SimpleDocument.all
      criteria.to_a
      SimpleDocument.delete_all
      criteria.each.to_a.size.should == 2
      criteria.size.should == 2
      criteria.count.should == 2
      criteria.first.should == docs.first
      criteria.last.should == docs.last
      criteria.empty?.should == false
      criteria.any?.should == true
      criteria.any? { |doc| doc.field1 == 1 }.should == true
      criteria.any? { |doc| doc.field1 == 3 }.should == false
    end
  end

  context 'when reloading the cache' do
    it 'reloads the cache' do
      criteria = SimpleDocument.all
      criteria.to_a
      SimpleDocument.destroy_all
      criteria.count.should == 2
      criteria.reload
      criteria.count.should == 0
    end
  end

  context 'when destroying items' do
    it 'reloads the cache' do
      criteria = SimpleDocument.all
      criteria.to_a
      SimpleDocument.create
      criteria.destroy_all
      criteria.count.should == 0
      SimpleDocument.all.count.should == 0
    end
  end

  context 'when deleting items' do
    it 'reloads the cache' do
      criteria = SimpleDocument.all
      criteria.to_a
      criteria.delete_all
      criteria.count.should == 0
    end
  end

  context 'when updating items' do
    it 'reloads the cache' do
      criteria = SimpleDocument.where(:field1 => 1)
      criteria.to_a
      criteria.count.should == 1
      criteria.update_all(:field1 => 2)
      criteria.count.should == 0
    end
  end

  context 'when disabling the cache' do
    it 'does not use the cache' do
      criteria = SimpleDocument.all.without_cache
      criteria.to_a
      SimpleDocument.destroy_all
      criteria.count.should == 0
    end
  end

  context 'when disabling the cache once hot' do
    it 'does not use the cache' do
      criteria = SimpleDocument.all
      criteria.to_a
      SimpleDocument.destroy_all
      criteria.count.should == 2
      criteria.without_cache.count.should == 0
    end
  end
end
