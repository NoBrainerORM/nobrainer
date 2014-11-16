require 'spec_helper'

describe 'NoBrainer geospatial' do
  before do
    define_class :City do
      include NoBrainer::Document
      field :name
      field :location, :type => NoBrainer::Geo::Point
      index :location, :geo => true
    end

    NoBrainer.sync_indexes
  end

  let!(:city) { City.create(:name => 'Boston', :location => NoBrainer::Geo::Point.new(71.0636, 42.3581)) }

  context 'when doing geospatial queries' do
    it 'is able to persist / reload a geopoint' do
      city.reload
      expect(city.location.latitude).to eq(42.3581)
    end
  end
end