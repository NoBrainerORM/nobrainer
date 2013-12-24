require 'spec_helper'

describe 'NoBrainer callbacks' do
  before { load_simple_document }

  context 'when using a simple validation' do
    before { SimpleDocument.validates :field1, :presence => true }

    it 'responds to valid?' do
      doc = SimpleDocument.new
      doc.valid?.should == false
      doc.field1 = 'hey'
      doc.valid?.should == true
    end

    it 'responds to invalid?' do
      doc = SimpleDocument.new
      doc.invalid?.should == true
      doc.field1 = 'hey'
      doc.invalid?.should == false
    end

    it 'adds errors' do
      SimpleDocument.create.errors.should be_present
    end

    context 'when not using the bang version' do
      let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

      it 'prevents create if invalid' do
        SimpleDocument.count.should == 0
      end

      context 'when passing :validate => false' do
        it 'returns true for save' do
          doc.field1 = nil
          doc.save(:validate => false).should == true
        end
      end

      context 'when passing nothing' do
        it 'returns false for save' do
          doc.field1 = nil
          doc.save.should == false
        end
      end

      it 'returns false for update_attributes' do
        doc.update_attributes(:field1 => nil).should == false
      end
    end

    context 'when using the bang version' do
      let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

      it 'throws an exception for create!' do
        expect { SimpleDocument.create! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end

      context 'when passing :validate => false' do
        it 'returns true for save!' do
          doc.field1 = nil
          doc.save!(:validate => false).should == true
        end
      end

      context 'when passing nothing' do
        it 'throws an exception for save!' do
          doc.field1 = nil
          expect { doc.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
        end
      end

      it 'throws an exception for update_attributes!' do
        expect { doc.update_attributes!(:field1 => nil) }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end
  end

  context 'when validating a unique field' do
    context 'with validates_uniqueness_of' do
      before { SimpleDocument.validates_uniqueness_of :field1 }
      let!(:doc) { SimpleDocument.create!(:field1 => 'ohai') }

      it 'cannot save a non-unique value' do
        doc2 = SimpleDocument.new field1: 'ohai'
        doc2.valid?.should == false
        expect { doc2.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end

    context 'without a scope' do
      before { SimpleDocument.validates :field1, :uniqueness => true }
      let!(:doc) { SimpleDocument.create!(:field1 => 'ohai') }

      it 'can save an existing document' do
        doc.valid?.should == true
        doc.save.should == true
      end

      it 'cannot save a non-unique value' do
        doc2 = SimpleDocument.new field1: 'ohai'
        doc2.valid?.should == false
        expect { doc2.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end

      it 'can save a unique value' do
        doc2 = SimpleDocument.new field1: 'okbai'
        doc2.valid?.should == true
        doc2.save.should == true
      end
    end

    context 'with a default scope' do
      before do
        SimpleDocument.class_eval do
          validates :field1, :uniqueness => true
          default_scope where(:field2 => 'hello')
        end
      end

      it 'does not use the default scope' do
        SimpleDocument.create!(field1: 'hello')
        SimpleDocument.new(field1: 'hello').valid?.should == false
      end
    end

    context 'with a single scope' do
      before { SimpleDocument.validates :field1, :uniqueness => {scope: :field2} }

      let!(:doc) { SimpleDocument.create!(:field1 => 'ohai', :field2 => 'there') }

      it 'cannot save a non-unique value in the same scope' do
        doc2 = SimpleDocument.new field1: 'ohai', field2: 'there'
        doc2.valid?.should == false
        expect { doc2.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end

      it 'can save a unique value in the same scope' do
        doc2 = SimpleDocument.new field1: 'okbai', field2: 'there'
        doc2.valid?.should == true
        doc2.save.should == true
      end

      it 'can save a non-unique value in a different scope' do
        doc2 = SimpleDocument.new field1: 'ohai', field2: 'now'
        doc2.valid?.should == true
        doc2.save.should == true
      end
    end

    context 'with multiple scopes' do
      before { SimpleDocument.validates :field1, :uniqueness => {scope: [:field2, :field3]} }

      let!(:doc) { SimpleDocument.create!(:field1 => 'ohai', :field2 => 'there', :field3 => 'bob') }

      it 'cannot save a non-unique value in all of the same scopes' do
        doc2 = SimpleDocument.new field1: 'ohai', field2: 'there', field3: 'bob'
        doc2.valid?.should == false
        expect { doc2.save! }.to raise_error(NoBrainer::Error::DocumentInvalid)
      end

      it 'can save a unique value in all of the same scopes' do
        doc2 = SimpleDocument.new field1: 'okbai', field2: 'there', field3: 'bob'
        doc2.valid?.should == true
        doc2.save.should == true
      end

      it 'can save a non-unique value when not all of the scopes match' do
        doc2 = SimpleDocument.new field1: 'ohai', field2: 'there', field3: 'jimmy'
        doc2.valid?.should == true
        doc2.save.should == true
        doc3 = SimpleDocument.new field1: 'ohai', field2: 'now', field3: 'bob'
        doc3.valid?.should == true
        doc3.save.should == true
      end
    end

    context 'with polymorphic classes' do
      before { load_polymorphic_models }

      context 'when applied on the parent' do
        before { Parent.validates :parent_field, :uniqueness => true }
        let!(:parent_doc) { Parent.create(:parent_field => 'ohai') }

        it 'validates in the scope of the parent' do
          Parent.new(:parent_field => 'ohai').valid?.should == false
          Child.new(:parent_field => 'ohai').valid?.should == false
          GrandChild.new(:parent_field => 'ohai').valid?.should == false
        end
      end

      context 'when applied on the child' do
        before { Child.validates :parent_field, :uniqueness => true }
        let!(:parent_doc) { Parent.create(:parent_field => 'ohai') }

        it 'validates in the scope of the child' do
          Parent.new(:parent_field => 'ohai').valid?.should == true
          Child.new(:parent_field => 'ohai').valid?.should == false
          GrandChild.new(:parent_field => 'ohai').valid?.should == false
        end
      end
    end
  end

  context 'when validating presence on a belongs_to relation' do
    before { load_blog_models }

    context 'when using validates' do
      before { Post.validates :author, :presence => true }

      context 'when the relation is not persisted' do
        it 'fails the validation' do
          Post.new(:author => Author.new).valid?.should == false
        end
      end

      context 'when the relation is persisted' do
        it 'passes the validation' do
          Post.new(:author => Author.create).valid?.should == true
        end
      end
    end

    context 'when using validates_presence_of' do
      before { Post.validates_presence_of :author }

      context 'when the relation is not persisted' do
        it 'fails the validation' do
          Post.new(:author => Author.new).valid?.should == false
        end
      end

      context 'when the relation is persisted' do
        it 'passes the validation' do
          Post.new(:author => Author.create).valid?.should == true
        end
      end
    end
  end

  context 'when using an ActiveModel validation' do
    context 'when using validates_XXX_of' do
      before { SimpleDocument.validates_numericality_of :field1 }
      it 'validates' do
        SimpleDocument.new(:field1 => 'hello').valid?.should == false
        SimpleDocument.new(:field1 => 3).valid?.should == true
      end
    end

    context 'when using validates' do
      before { SimpleDocument.validates :field1, :numericality => true }
      it 'validates' do
        SimpleDocument.new(:field1 => 'hello').valid?.should == false
        SimpleDocument.new(:field1 => 3).valid?.should == true
      end
    end
  end
end
