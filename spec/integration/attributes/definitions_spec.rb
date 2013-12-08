require 'spec_helper'

describe NoBrainer do
  before { load_polymorphic_models }

  describe 'fields' do
    # Defining another field after Child has been defined.
    before { Parent.field :other_parent_field }
    before { Parent.disable_timestamps }

    it 'returns a hash of fields' do
      Parent.fields.keys.should      =~ [:id, :parent_field, :other_parent_field]
      Child.fields.keys.should       =~ [:id, :_type, :parent_field, :other_parent_field, :child_field]
      GrandChild.fields.keys.should  =~ [:id, :_type, :parent_field, :other_parent_field, :child_field, :grand_child_field]
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
end
