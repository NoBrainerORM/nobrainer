require 'spec_helper'

describe 'validations' do
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
      doc = SimpleDocument.new
      doc.save?
      doc.errors.should be_present
    end

    context 'when using the ? version' do
      let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

      it 'prevents create if invalid' do
        SimpleDocument.count.should == 0
      end

      context 'when passing :validate => false' do
        it 'returns true for save?' do
          doc.field1 = nil
          doc.save?(:validate => false).should == true
        end
      end

      context 'when passing nothing' do
        it 'returns false for save?' do
          doc.field1 = nil
          doc.save?.should == false
        end
      end

      it 'returns false for update?' do
        doc.update?(:field1 => nil).should == false
      end
    end

    context 'when using the normal version' do
      let(:doc) { SimpleDocument.create(:field1 => 'ohai') }

      it 'throws an exception for create' do
        expect { SimpleDocument.create }
          .to raise_error(NoBrainer::Error::DocumentInvalid, /Field1 can't be blank/)
      end

      context 'when passing :validate => false' do
        it 'returns true for save' do
          doc.field1 = nil
          doc.save?(:validate => false).should == true
        end
      end

      context 'when passing nothing' do
        it 'throws an exception for save' do
          doc.field1 = nil
          expect { doc.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
        end
      end

      it 'throws an exception for update' do
        expect { doc.update(:field1 => nil) }.to raise_error(NoBrainer::Error::DocumentInvalid)
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

    context 'when using validate' do
      before do
        SimpleDocument.class_eval do
          validate :some_validator
          def some_validator
            errors.add(:base, "oh no")
          end
        end
      end

      it 'validates' do
        SimpleDocument.new.valid?.should == false
      end
    end
  end

  context 'when using validates on the field' do
    before { SimpleDocument.field :field1, :validates => { :numericality => true } }

    it 'validates' do
      SimpleDocument.new(:field1 => 'hello').valid?.should == false
      SimpleDocument.new(:field1 => 3).valid?.should == true
    end
  end

  context 'when using validates on a belongs_to' do
    before { load_blog_models }
    before { Comment.belongs_to :post, :validates => { :presence => true } }

    it 'validates' do
      post = Post.create
      Comment.new.valid?.should == false
      Comment.new(:post => post).valid?.should == true
    end
  end

  context 'when using unique on the field' do
    before { SimpleDocument.field :field1, :unique => true }

    it 'validates' do
      SimpleDocument.new(:field1 => 123).save?.should == true
      SimpleDocument.new(:field1 => 123).save?.should == false
    end
  end

  context 'when using uniq on the field' do
    before { SimpleDocument.field :field1, :uniq => true }

    it 'validates' do
      SimpleDocument.new(:field1 => 123).save?.should == true
      SimpleDocument.new(:field1 => 123).save?.should == false
    end
  end

  context 'when using format on the field' do
    before { SimpleDocument.field :field1, :format => /\A[a-z]+\z/ }

    it 'validates' do
      SimpleDocument.new(:field1 => 'Ohai').valid?.should == false
      SimpleDocument.new(:field1 => 'ohai').valid?.should == true
    end
  end

  context 'when using length on the field' do
    context 'when using ranges' do
      before { SimpleDocument.field :field1, :length => (4..10) }

      it 'validates' do
        SimpleDocument.new(:field1 => 'Oha').valid?.should == false
        SimpleDocument.new(:field1 => 'Ohai').valid?.should == true
        SimpleDocument.new(:field1 => '1234567890').valid?.should == true
        SimpleDocument.new(:field1 => '12345678901').valid?.should == false
      end
    end

    context 'when using options' do
      before { SimpleDocument.field :field1, :length => { :minimum => 2 } }

      it 'validates' do
        SimpleDocument.new(:field1 => 'O').valid?.should == false
        SimpleDocument.new(:field1 => 'Oh').valid?.should == true
      end
    end

    context 'when using min_length' do
      before { SimpleDocument.field :field1, :min_length => 2 }

      it 'validates' do
        SimpleDocument.new(:field1 => 'O').valid?.should == false
        SimpleDocument.new(:field1 => 'Oh').valid?.should == true
      end
    end

    context 'when using max_length' do
      before { SimpleDocument.field :field1, :max_length => 10 }

      it 'validates' do
        SimpleDocument.new(:field1 => '1234567890').valid?.should == true
        SimpleDocument.new(:field1 => '12345678901').valid?.should == false
      end
    end
  end

  context 'when using in on the field' do
    before { SimpleDocument.field :field1, :in => %w(a b c) }

    it 'validates' do
      SimpleDocument.new(:field1 => nil).valid?.should == false
      SimpleDocument.new(:field1 => 'a').valid?.should == true
      SimpleDocument.new(:field1 => 'b').valid?.should == true
      SimpleDocument.new(:field1 => 'c').valid?.should == true
      SimpleDocument.new(:field1 => 'd').valid?.should == false
    end
  end

  context 'when validating belongs_to' do
    context 'the foreign_key should always be nil or valid' do
      before { load_blog_models }
      before { Comment.belongs_to :post }

      it 'validates' do
        post = Post.create
        c = Comment.create({}, :validate => false)

        c.post = Post.new
        expect { c.valid? }.to raise_error(NoBrainer::Error::AssociationNotPersisted)

        c.post = post
        c.send("post_#{Post.pk_name}").should == post.pk_value
        c.valid?.should == true

        c.post = nil
        c.send("post_#{Post.pk_name}").should == nil
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", '123')
        c.valid?.should == false
        c.errors.full_messages.first.should =~ /Post\(#{Post.pk_name}: 123\) is not found/

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == true
        Post.delete_all
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == false
      end
    end

    context 'when using required => true on a belongs_to' do
      before { load_blog_models }
      before { Comment.belongs_to :post, :required => true }

      it 'validates' do
        post = Post.create
        c = Comment.create({}, :validate => false)

        c.post = Post.new
        expect { c.valid? }.to raise_error(NoBrainer::Error::AssociationNotPersisted)

        c.post = post
        c.send("post_#{Post.pk_name}").should == post.pk_value
        c.valid?.should == true

        c.post = nil
        c.send("post_#{Post.pk_name}").should == nil
        c.valid?.should == false

        c.send("post_#{Post.pk_name}=", '123')
        c.valid?.should == false

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == true
        Post.delete_all
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == false
      end
    end

    context 'when using validates => false on a belongs_to' do
      before do
        define_class :Post do
          include NoBrainer::Document
        end
        define_class :Comment do
          include NoBrainer::Document
          belongs_to :post, :validates => false
        end
      end

      it 'validates' do
        post = Post.create
        c = Comment.create({}, :validate => false)

        c.post = Post.new
        expect { c.valid? }.to raise_error(NoBrainer::Error::AssociationNotPersisted)

        c.post = post
        c.send("post_#{Post.pk_name}").should == post.pk_value
        c.valid?.should == true

        c.post = nil
        c.send("post_#{Post.pk_name}").should == nil
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", '123')
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == true
        Post.delete_all
        c.valid?.should == true

        c.send("post_#{Post.pk_name}=", post.pk_value)
        c.valid?.should == true
      end
    end
  end

  context 'when the field does not change' do
    before { SimpleDocument.validates :field1, :field2, :inclusion => %w(a b) }

    it 'does not call its validators' do
      SimpleDocument.new.valid?.should == false
      SimpleDocument.create({:field2 => 'xx'}, :validate => false)
      doc = SimpleDocument.first
      doc.valid?.should == true
      doc.field1 = 'x'
      doc.valid?.should == false
      doc.field1 = 'a'
      doc.valid?.should == true
      doc.field2 = 'xx'
      doc.valid?.should == true
      doc.field2 = 'yy'
      doc.valid?.should == false
      doc.field2 = 'a'
      doc.valid?.should == true
    end
  end

  context 'when the validated attribute is not a field' do
    before do
      SimpleDocument.class_eval do
        alias_method :some_attr, :field1
        validates :some_attr, :presence => true
      end
    end

    it 'always calls its validator' do
      SimpleDocument.new.valid?.should == false
      SimpleDocument.create({}, :validate => false)
      doc = SimpleDocument.first
      doc.valid?.should == false
      doc.field1 = 'a'
      doc.valid?.should == true
    end
  end
end
