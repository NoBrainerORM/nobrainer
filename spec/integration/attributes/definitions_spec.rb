require 'spec_helper'

describe NoBrainer do
  before { load_polymorphic_models }

  describe 'fields' do
    # Defining another field after Child has been defined.
    before { Parent.field :other_parent_field }

    it 'returns a hash of fields' do
      Parent.fields.keys.should      =~ [:id, :parent_field, :other_parent_field]
      Child.fields.keys.should       =~ [:id, :_type, :parent_field, :other_parent_field, :child_field]
      GrandChild.fields.keys.should  =~ [:id, :_type, :parent_field, :other_parent_field, :child_field, :grand_child_field]
    end
  end
end
