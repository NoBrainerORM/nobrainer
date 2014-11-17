require 'spec_helper'

describe 'missing attributes' do
  before { load_simple_document }

  let(:fields) { doc.attributes.keys }

  context 'with pluck()' do
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

    it 'selects fields' do
      SimpleDocument.pluck(:field1, :field2).raw.first.keys.should =~ %w(field1 field2)
    end

    it 'can be reversed' do
      SimpleDocument.pluck(:field1).pluck(:field1 => false).raw.first.keys.should =~ fields
      SimpleDocument.pluck(:field1, :field2).pluck('field1' => false).raw.first.keys.should =~ %w(field2)
      SimpleDocument.pluck(:field1 => false).raw.first.keys.should =~ fields
    end

    it 'does not allow to remove the primary key on models' do
      msg = "The primary key is not accessible. Use .raw or add `:#{SimpleDocument.pk_name}' to pluck()"
      expect { SimpleDocument.pluck(:field1).first }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
      SimpleDocument.pluck(fields - %w(field1 field2)).first.attributes.keys.should =~ fields - %w(field1 field2)
    end
  end

  context 'with without()' do
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

    it 'reject fields' do
      SimpleDocument.without(:field1).raw.first.keys.should =~ fields - %w(field1)
    end

    it 'can be reversed' do
      SimpleDocument.without(:field1).without(:field1 => false).raw.first.keys.should =~ fields
      SimpleDocument.without(:field1, :field2).without('field1' => false).raw.first.keys.should =~ fields - %w(field2)
      SimpleDocument.without(:field1 => false).raw.first.keys.should =~ fields
    end


    it 'does not allow to remove the primary key on models' do
      msg = "The primary key is not accessible. Use .raw or remove `:#{SimpleDocument.pk_name}' from without()"
      expect { SimpleDocument.without(:field1, SimpleDocument.pk_name).first }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
      SimpleDocument.without(:field1).first.attributes.keys.should =~ fields - %w(field1)
    end
  end

  context 'with both pluck() and without()' do
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

    it 'leaves pluck() the priority' do
      SimpleDocument.pluck(:field1).without(:field1).raw.first.keys.should =~ %w(field1)
    end
  end

  context 'with polymorphism' do
    before { load_polymorphic_models }
    let!(:doc) { Child.create(:parent_field => 1, :child_field => 2) }

    context 'with pluck()' do
      it 'does not allow to remove the _type on models' do
        msg = "The subclass type is not accessible. Use .raw or add `:_type' to pluck()"
        fields = [Parent.pk_name, :_type, :child_field].map(&:to_s)
        expect { Parent.pluck(fields - %w(_type)).first }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
        Parent.pluck(fields).first.attributes.keys.should =~ fields
      end
    end

    context 'with without()' do
      it 'does not allow to remove the _type on models' do
        msg = "The subclass type is not accessible. Use .raw or remove `:_type' from without()"
        expect { Parent.without(:_type, :child_field).first }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
        Parent.without(:child_field).first.attributes.keys.should =~ fields - %w(child_field)
      end
    end
  end

  context 'with aliases' do
    before { SimpleDocument.field :field1, :store_as => :f1 }
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

    context 'with pluck()' do
      it 'aliases fields' do
        SimpleDocument.pluck(:field1, :field2).raw.first.keys.should =~ %w(f1 field2)
      end
    end

    context 'with without()' do
      it 'aliases fields' do
        SimpleDocument.without(:field1).raw.first.keys.should =~ fields - %w(field1)
      end
    end
  end

  context 'when reading from missing fields' do
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3) }

    context 'with pluck()' do
      it 'throws on missing fields' do
        msg = "The attribute `field1' is not accessible, add `:field1' to pluck()"
        expect { SimpleDocument.pluck(fields - %w(field1)).first.field1 }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
        SimpleDocument.pluck(fields - %w(field1)).first.field2.should == 2
      end
    end

    context 'with without()' do
      it 'throws on missing fields' do
        msg = "The attribute `field1' is not accessible, remove `:field1' from without()"
        expect { SimpleDocument.without(:field1).first.field1 }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
        SimpleDocument.without(:field1).first.field2.should == 2
      end
    end
  end

  context 'when using dynamic attributes' do
    before { SimpleDocument.class_eval { include NoBrainer::Document::DynamicAttributes } }
    let!(:doc) { SimpleDocument.create(:field1 => 1, :field2 => 2, :field3 => 3, :field4 => 4) }

    context 'when reading from missing fields' do
      it 'no longer throws on missing fields' do
        msg = "The attribute `field4' is not accessible, remove `:field4' from without()"
        expect { SimpleDocument.without(:field4).first[:field4] }.to raise_error(NoBrainer::Error::MissingAttribute, msg)
        SimpleDocument.without(:field3).first['field4'].should == 4
      end
    end

    context 'when writing to missing fields' do
      it 'no longer throws on missing fields' do
        doc = SimpleDocument.without(:field4).first
        doc['field4'] = 'x'
        doc['field4'].should == 'x'
        doc.reload
        doc['field4'].should == 4
      end
    end
  end
end
