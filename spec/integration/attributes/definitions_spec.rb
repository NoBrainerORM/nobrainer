require 'spec_helper'

describe NoBrainer do
  before { load_polymorphic_models }

  describe 'fields' do
    # Defining another field after Child has been defined.
    before { Parent.field :other_parent_field }

    it 'returns a hash of fields' do
      Parent.fields.keys.should      =~ [Parent.pk_name, :parent_field, :other_parent_field]
      Child.fields.keys.should       =~ [Parent.pk_name, :_type, :parent_field, :other_parent_field, :child_field]
      GrandChild.fields.keys.should  =~ [Parent.pk_name, :_type, :parent_field, :other_parent_field, :child_field, :grand_child_field]
    end
  end

  context 'when using field defaults' do
    before { load_simple_document }
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
    before { load_simple_document }
    before { SimpleDocument.create }

    it 'will load the default value into a retrieved instance' do
      SimpleDocument.field :field1, default: 'foo'
      SimpleDocument.first.field1.should == 'foo'
    end
  end

  context 'when using a proc as a default' do
    before { load_simple_document }
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

  context 'when using reserved attribute names' do
    before { load_simple_document }

    it 'raises' do
      expect { SimpleDocument.field :in }.to raise_error
      expect { SimpleDocument.field :or }.to raise_error
      expect { SimpleDocument.field :and }.to raise_error
    end
  end

  context 'when removing fields' do
    before { load_simple_document }

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
end
