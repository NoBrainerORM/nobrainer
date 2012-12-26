require 'spec_helper'

describe 'NoBrainer id' do
  before { load_simple_document }

  it 'can be used to order documents by time' do
    range = (0..20)
    Time.stub(:now).and_return(*range.map { |i| Time.at(i) })
    range.each { |i| SimpleDocument.create(:field1 => i) }
    SimpleDocument.all.order_by(:id => :asc).map(&:field1).to_a.should == range.to_a
  end
end
