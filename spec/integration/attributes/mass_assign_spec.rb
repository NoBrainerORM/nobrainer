require 'spec_helper'

if NoBrainer.rails3?
  describe NoBrainer do
    before { load_simple_document }

    before do
      SimpleDocument.class_eval do
        field :protected_field1
        field :protected_field2

        attr_protected :protected_field1, :protected_field2
        attr_protected :protected_field2, :as => :admin
      end
    end

    let(:attributes) { {:field1 => 'ohai',
                        :protected_field1 => 'admin_only',
                        :protected_field2 => 'dont_touch'} }

    context 'when using no options' do
      context 'when using new' do
        it 'protects attributes' do
          doc = SimpleDocument.new(attributes)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == nil
          doc.protected_field2.should == nil
        end
      end

      context 'when using create' do
        it 'protects attributes' do
          doc = SimpleDocument.create(attributes)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == nil
          doc.protected_field2.should == nil
        end
      end

      context 'when using update_attributes' do
        it 'protects attributes' do
          doc = SimpleDocument.create
          doc.update_attributes(attributes)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == nil
          doc.protected_field2.should == nil
        end
      end
    end

    context 'when using a role' do
      context 'when using new' do
        it 'protects some attributes' do
          doc = SimpleDocument.new(attributes, :as => :admin)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == nil
        end
      end

      context 'when using create' do
        it 'protects some attributes' do
          doc = SimpleDocument.create(attributes, :as => :admin)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == nil
        end
      end

      context 'when using update_attributes' do
        it 'protects some attributes' do
          doc = SimpleDocument.create
          doc.update_attributes(attributes, :as => :admin)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == nil
        end
      end
    end

    context 'when using a without_protection' do
      context 'when using new' do
        it 'does not protects attributes' do
          doc = SimpleDocument.new(attributes, :without_protection => true)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == 'dont_touch'
        end
      end

      context 'when using create' do
        it 'does not protects attributes' do
          doc = SimpleDocument.create(attributes, :without_protection => true)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == 'dont_touch'
        end
      end

      context 'when using update_attributes' do
        it 'does not protects attributes' do
          doc = SimpleDocument.create
          doc.update_attributes(attributes, :without_protection => true)
          doc.field1.should == 'ohai'
          doc.protected_field1.should == 'admin_only'
          doc.protected_field2.should == 'dont_touch'
        end
      end
    end
  end
end
