# frozen_string_literal: true

require 'spec_helper'

describe 'belongs_to polymorphic' do
  before do
    load_belongs_to_polymorphic_models
    NoBrainer.sync_indexes
  end

  let(:event) { Event.create }
  let!(:pictures) do
    3.times.map { Picture.create(imageable: restaurant, mime: 'image/png') }
  end
  let(:restaurant) { Restaurant.create }

  context 'when setting polymorphic: true and class_name' do
    it 'raises an error' do
      expect do
        Picture.belongs_to(:picturable, polymorphic: true, class_name: 'Test')
      end.to raise_error(RuntimeError, /cannot set class_name on a polymorphic/)
    end
  end

  context 'when setting polymorphic: true and required but not assigning document' do
    it 'raises an error' do
      Picture.belongs_to(:picturable, polymorphic: true, required: true)

      doc = Picture.create
      expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      doc.errors.full_messages.first.should == "Picturable can't be blank"
    end
  end

  context 'when eager loading on a belongs_to association with all documents ' \
          'from the same root class' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.twice

      Picture.eager_load(:imageable).each do |picture|
        expect(picture.imageable).to eql(restaurant)
      end
    end
  end

  context 'when eager loading on a belongs_to association with at least one ' \
          'document with a different root class' do
    before { Picture.create(imageable: event, mime: 'image/png') }

    it 'eagers load' do
      expect do
        Image.eager_load(:imageable).to_a
      end.to raise_error(NoBrainer::Error::PolymorphicAssociationWithDifferentTypes)
    end
  end

  context 'foreign_type is nil' do
    context 'target is loaded' do
      it 'returns the target' do
        picture = Picture.create(imageable: restaurant)
        picture.imageable_type = nil
        picture.save!

        expect(picture.imageable_type).to be_nil
        expect(picture.imageable).to be(restaurant)
      end
    end

    context 'target is not loaded' do
      it 'returns nil' do
        picture = Picture.create(imageable__id_: restaurant._id_)

        expect(picture.imageable_type).to be_nil
        expect(picture.imageable).to be_nil
      end
    end
  end

  context 'foreign_type is a non exiting class' do
    it 'raises' do
      expect do
        Picture.create(imageable__id_: 'ABCD', imageable_type: 'SmartDeveloper')
      end.to raise_error NameError, 'uninitialized constant SmartDeveloper'
    end
  end

  context 'creating a polymorphic model document' do
    it 'saves the model class as type and model id' do
      picture = Picture.create(imageable: restaurant, mime: 'image/jpeg')

      expect(picture.imageable_type).to eql(restaurant.class.name)
      # `imageable__id_` instead of imageable_id since the primary key
      # has been changed for Rspec, see spec/spec_helper.rb line 32-33.
      expect(picture.imageable__id_).to eql(restaurant._id_)
    end
  end

  context 'accessing a has_one polymorphic model document' do
    it 'returns the associated document' do
      # Do not use the imageable setter in order to prevent from loading it and
      # being sure to pass into the polymorphic_read method, after the loaded?
      logo = Logo.create(imageable_type: 'Restaurant',
                         imageable__id_: restaurant._id_,
                         mime: 'image/png')

      expect(Restaurant.find(restaurant._id_).logo).to eql(Logo.find(logo._id_))
    end
  end

  context 'accessing a has_many polymorphic model document' do
    it 'returns the associated documents' do
      picture1 = Picture.create(imageable: restaurant, mime: 'image/png')
      picture2 = Picture.create(imageable: restaurant, mime: 'image/png')

      expect(restaurant.pictures.to_a).to eql(pictures | [picture1, picture2])

      picture3 = Picture.create(imageable: event, mime: 'image/png')

      expect(event.photos.to_a).to eql([picture3])
    end
  end

  context 'accessing a has_many through model document' do
    it 'returns the associated documents' do
      restaurant_event1 = Event.create(restaurant: restaurant)
      restaurant_event2 = Event.create(restaurant: restaurant)

      picture1 = Picture.create(imageable: restaurant_event1, mime: 'image/png')
      picture2 = Picture.create(imageable: restaurant_event1, mime: 'image/png')
      picture3 = Picture.create(imageable: restaurant_event2, mime: 'image/png')

      expect(restaurant.photos.to_a).to eql([picture1, picture2, picture3])
    end
  end

  context 'proxying a has_many association through a polymorphic association' do
    it 'returns the associated documents' do
      event = Event.create(restaurant: restaurant)

      picture = Picture.create(imageable: event, mime: 'image/png')
      guillaume = IdentifiedPerson.create(picture: picture,
                                          fullname: 'Guillaume Briat')
      alexandre = IdentifiedPerson.create(picture: picture,
                                          fullname: 'Alexandre Astier')

      picture = Picture.create(imageable: event, mime: 'image/png')
      lionnel = IdentifiedPerson.create(picture: picture,
                                        fullname: 'Lionnel Astier')
      franck = IdentifiedPerson.create(picture: picture,
                                       fullname: 'Franck Pitiot')

      expect(event.people.to_a).to eql([guillaume, alexandre, lionnel, franck])
    end
  end

  context 'joining on the imageable belongs_to' do
    it 'fails' do
      expect do
        Picture.join(:imageable).map(&:imageable)
      end.to raise_error(/join().*polymorphic/)
    end
  end

  context 'joining on a has_many as: :imageable' do
    it 'joins' do
      expect(Restaurant.join(:pictures).flat_map(&:pictures)).to eql(pictures)
    end
  end
end
