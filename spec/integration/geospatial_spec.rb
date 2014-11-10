require 'spec_helper'

describe 'NoBrainer geospatial' do
  before { load_geospatial_example }

  let!(:city) { City.create(:name => 'Boston', :location => NoBrainer::GeoPoint.new(71.0636, 42.3581)) }

  context 'when doing geospatial queries' do
    it 'finds by location' do
      City.nearest(NoBrainer::GeoPoint.new(71.0636, 42.3581), :index => 'location').count.should == 1
    end
  end
end