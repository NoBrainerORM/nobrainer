require 'spec_helper'

describe 'attributes' do
  before { load_simple_document }

  describe 'access' do
    let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

    it 'allows attribute access through []' do
      doc['field1'].should == 'hello'
      doc[:field1].should == 'hello'
    end

    it 'allows attribute update through []=' do
      doc['field2'] = 'brave world'
      doc['field2'].should == 'brave world'
      doc.field2.should == 'brave world'
      doc.attributes['field2'].should == 'brave world'
    end
  end

  describe 'polymorphic fields' do
    before { load_polymorphic_models }

    # Defining another field after Child has been defined.
    before { Parent.field :other_parent_field }

    it 'returns a hash of fields' do
      Parent.fields.keys.should      =~ [Parent.pk_name, :parent_field, :other_parent_field]
      Child.fields.keys.should       =~ [Parent.pk_name, :_type, :parent_field, :other_parent_field, :child_field]
      GrandChild.fields.keys.should  =~ [Parent.pk_name, :_type, :parent_field, :other_parent_field, :child_field, :grand_child_field]
    end
  end

  describe 'defaults' do
    context 'when using field defaults' do
      before { SimpleDocument.field :field1, default: 'foo'}

      it 'sets the default value when a new instance is made' do
        doc = SimpleDocument.new
        doc.field1.should == 'foo'
      end

      it 'sets the default value when a new instance is created' do
        SimpleDocument.create
        SimpleDocument.where(:field1 => 'foo').count.should == 1
      end

      it 'still allows you to change the value' do
        doc = SimpleDocument.new field1: 'bar'
        doc.field1.should == 'bar'
      end
    end

    context 'when applying field defaults later' do
      before { SimpleDocument.create }

      it 'will load the default value into a retrieved instance' do
        SimpleDocument.field :field1, default: 'foo'
        SimpleDocument.first.field1.should == 'foo'
      end
    end

    context 'when using a proc as a default' do
      before { SimpleDocument.field :field1, default: ->{ $default_value } }

      it 'will load the default value into a retrieved instance' do
        $default_value = 'ohai'
        SimpleDocument.create
        SimpleDocument.where(:field1 => 'ohai').count.should == 1
        $default_value = 'hello'
        SimpleDocument.create
        SimpleDocument.where(:field1 => 'hello').count.should == 1
      end
    end
  end

  context 'when using reserved attribute names' do
    it 'raises' do
      expect { SimpleDocument.field :in }.to raise_error
      expect { SimpleDocument.field :or }.to raise_error
      expect { SimpleDocument.field :and }.to raise_error
    end
  end

  context 'when removing fields' do
    def methods(model)
      model.methods.grep(/methods/).map { |m| model.send(m) }.reduce(:+)
    end

    it 'cleans up' do
      original_methods = methods(SimpleDocument)
      original_indexes = SimpleDocument.indexes.dup
      original_consts = SimpleDocument.constants
      # original_fields = SimpleDocument.fields.dup

      # Logic overriding 'def _field' should be triggered here.
      SimpleDocument.field :attr, :type        => SimpleDocument::Boolean,
                                  :unique      => true,
                                  :index       => true,
                                  :readonly    => true,
                                  :primary_key => true
      SimpleDocument.remove_field :attr

      methods(SimpleDocument).should =~ original_methods
      SimpleDocument.indexes.should == original_indexes
      SimpleDocument.constants.should =~ original_consts
      # TODO the procs are making the == fail.
      # SimpleDocument.fields.should == original_fields
    end
  end

  context 'when calling inspect' do
    let(:doc) { SimpleDocument.new(SimpleDocument.pk_name => 'hello', :field2 => 2, :field1 => 1, :field3 => 3) }

    it 'shows the attributes' do
      doc.inspect.should == "#<SimpleDocument #{SimpleDocument.pk_name}: \"hello\", field1: 1, field2: 2, field3: 3>"
    end
  end

  context 'when using non permitted attributes' do
    it 'raises' do
      expect { SimpleDocument.new(permitted_attributes) }.to_not raise_error
      expect { SimpleDocument.new(non_permitted_attributes) }.to raise_error(ActiveModel::ForbiddenAttributesError)

      expect { SimpleDocument.new.tap { |doc| doc.assign_attributes(permitted_attributes) } }
        .to_not raise_error
      expect { SimpleDocument.new.tap { |doc| doc.assign_attributes(non_permitted_attributes) } }
        .to raise_error(ActiveModel::ForbiddenAttributesError)
    end
  end

  describe 'dynamic attributes' do
    before do
      SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
    end

    let!(:doc) { SimpleDocument.create(dynamic_field1: 'hello') }

    it 'allows dynamic attribute access through []' do
      doc['dynamic_field1'].should == 'hello'
      doc[:dynamic_field1].should == 'hello'
    end

    it 'allows attribute update through []=' do
      doc['dynamic_field2'] = 'world'
      doc['dynamic_field2'].should == 'world'
      doc.attributes['dynamic_field2'].should == 'world'
    end

    it 'persists dynamic attributes' do
      doc['dynamic_field2'] = 'world'
      doc.save
      doc.reload
      doc['dynamic_field2'].should == 'world'
    end

    it 'tracks dynamic attributes' do
      doc['dynamic_field'] = 'hello'
      doc.changes.should == {'dynamic_field' => [nil, 'hello']}
      doc.save
      doc['dynamic_field'] = 'world'
      doc.changes.should == {'dynamic_field' => ['hello', 'world']}
    end
  end

  describe 'hashes' do
    let(:doc) { SimpleDocument.create }

    it 'saves hashes properly' do
      doc.field1 = {'hello' => 'world'}
      doc.save
      doc.field1 = {'ohai' => ':)'}
      doc.save
      doc.reload
      doc.field1.should == {'ohai' => ':)'}
    end
  end

  describe 'read only fields' do
    context 'when trying to assign a readonly field' do
      it 'raises' do
        SimpleDocument.field :field1, :readonly => true
        doc = SimpleDocument.create(:field1 => 'hello')
        expect { doc.update(:field1 => 'ohno') }.to raise_error(NoBrainer::Error::ReadonlyField)
        expect { doc.update(SimpleDocument.pk_name => 'ohno') }.to raise_error(NoBrainer::Error::ReadonlyField)
      end
    end
  end

  describe 'raw_attribute' do
    before do
      SimpleDocument.class_eval do
        def field1
          "hello #{super}"
        end

        def field1=(value)
          super(value.upcase)
        end
      end
    end

    let(:doc) { SimpleDocument.new }

    it 'bypasses getter' do
      doc.field1 = 'bonjour'
      doc.attributes[:field1].should == 'hello BONJOUR'

      doc.raw_attributes[:field1] = 'bonjour'

      doc.save
      doc.reload

      doc.raw_attributes[:field1].should == 'bonjour'
    end
  end
end
