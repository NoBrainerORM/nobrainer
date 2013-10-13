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
    before { SimpleDocument.field :has_default, default: 'foo'}

    it 'sets the default value when a new instance is created' do
      doc = SimpleDocument.new
      doc.has_default.should == 'foo'
    end

    it 'still allows you to change the value' do
      doc = SimpleDocument.new has_default: 'bar'
      doc.has_default.should == 'bar'
    end
  end
end
