require 'spec_helper'

describe 'NoBrainer geospatial' do
  before { load_geospatial_example }

  let!(:city) { City.create(:name => 'Boston', :location => NoBrainer::Point.new(71.0636, 42.3581)) }

  context 'when doing geospatial queries' do
    it 'finds by location' do
      City.nearest(NoBrainer::Point.new(71.0636, 42.3581), :index => 'location').where({}).count.should == 1
    end
  end
end