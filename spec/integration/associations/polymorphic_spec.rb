require 'spec_helper'

describe 'polymorphic association' do
  before { load_polymorphically_associated_models }

  context 'when the association is not set' do
    let(:picture) { Picture.create }
    it 'returns nil' do
      picture.imageable.should == nil
    end
  end

  context 'with just one' do
    let!(:product) { Product.create }
    let!(:picture) { Picture.create(:imageable => product) }

    it 'counts models' do
      Product.all.count.should == 1
      Picture.all.count.should == 1
    end

    it 'has belongs_to field' do
      picture.imageable.should == product
    end

    it 'persists when reloaded' do
      picture.reload
      picture.imageable.should == product
    end

    it 'finds associated value' do
      product.reload
      product.pictures.to_a.should == [picture]
    end

    it 'cannot preload' do
      expect { Picture.eager_load(:imageable).all.to_a }.to raise_error(/polymorphic/)
    end
  end

  context 'with two different types' do
    let!(:product) { Product.create }
    let!(:employee) { Employee.create }
    let!(:product_picture) { Picture.create(:imageable => product) }
    let!(:employee_picture) { Picture.create(:imageable => employee) }

    it 'has correct values after reloading' do
      product.reload
      employee.reload
      product_picture.reload
      employee_picture.reload

      product.pictures.should == [product_picture]
      employee.picture.should == employee_picture
      product_picture.imageable.should == product
      employee_picture.imageable.should == employee
    end
  end

  context 'with multiple pictures' do
    let!(:product) { Product.create }
    let!(:picture_a) { Picture.create(:imageable => product) }
    let!(:picture_b) { Picture.create(:imageable => product) }

    it 'counts models' do
      Product.count.should == 1
      Picture.count.should == 2
    end

    it 'finds pictures' do
      product.pictures.to_a.should == [picture_a, picture_b]
    end
  end
end
