require 'spec_helper'

describe 'belongs_to' do
  before { load_blog_models }

  context 'when the association is not set' do
    let(:comment) { Comment.create }
    it 'returns nil' do
      comment.post.should == nil

      comment.post.should == nil
    end
  end

  context 'when the association is set with the id' do
    let(:post)    { Post.create }
    let(:comment) { Comment.create("post_#{Post.pk_name}" => post.pk_value) }

    it 'returns the object' do
      comment.post.should == post
    end
  end

  context 'when the association is set with the object' do
    let(:post)    { Post.create }
    let(:comment) { Comment.create(:post => post) }

    it 'returns the object' do
      comment.post.should == post
    end

    it 'doesnt save automatically' do
      comment.post = nil
      comment.reload
      comment.post.should == post
    end

    it 'persists when saved' do
      comment.post = nil
      comment.save
      comment.reload
      comment.post.should == nil

      comment.post = post
      comment.save
      comment.reload
      comment.post.should == post
    end
  end

  context 'when the association is set with a non persisted object' do
    let(:post)    { Post.create }
    let(:comment) { Comment.create(:post => post) }

    it 'does not persist the target' do
      comment.reload
      comment.post.should == post
      post2 = Post.new
      comment.post = post2
      post2.should_not be_persisted
      comment.post.should == post2
      expect { comment.save }.to raise_error NoBrainer::Error::AssociationNotPersisted
      post2.save
      comment.save
    end
  end

  context 'when the association is set with a wrong object type' do
    let(:comment) { Comment.create(:post => post) }

    it 'raises' do
      expect { Comment.create(:post => Comment.new) }.to raise_error NoBrainer::Error::InvalidType
    end
  end

  context 'when the association is set with a different primary_key' do
    before { load_columnist_models }
    let(:columnist) { Columnist.create(:employee_id => 4500) }
    let(:article)   { Article.create(:columnist_employee_id => columnist.employee_id) }

    it 'returns the object' do
      article.columnist.should == columnist
      article.columnist_employee_id.should == 4500
    end
  end

  context 'when the association is set with a different foreign_key' do
    before { load_columnist_models }
    let(:article) { Article.create(:slug => 'shortened-slugged-title') }
    let(:note)    { Footnote.create(:article_slug_url => article.slug) }

    it 'returns the object' do
      note.article.should == article
      note.article_slug_url.should == 'shortened-slugged-title'
    end
  end

  context 'when a custom primary key model is used' do
    before { load_album_models }

    let(:album)   { Album.create(:slug => 'slug') }
    let(:picture) { Picture.create(:album => album) }

    it 'should use the primary key properly' do
      picture.album.should == album
      picture.album_slug.should == 'slug'
    end

    context 'when the custom pk_name is known and different' do
      it 'should fails the belongs_to declaration' do
        expect { define_class :Artist do
          include NoBrainer::Document
          belongs_to :album
        end }.to raise_error(/specify the primary_key name.*belongs_to :album, :primary_key => :slug/m)
      end
    end

    context 'when the custom pk_name is unknown' do
      it 'does not fail the belongs_to declaration' do
        expect { define_class :Artist do
          include NoBrainer::Document
          belongs_to :some_unknown_class
        end }.to_not raise_error
      end
    end
  end

  context 'when using two belongs_to on the same class name' do
    it 'errors due to foreign key conflicts' do
      expect { define_class('SomePost') do
        include NoBrainer::Document
        belongs_to :some_author, :class_name => 'Author', :foreign_key => "author_#{Author.pk_name}"
        belongs_to :author
      end }.to raise_error(/Cannot declare `author' in SomePost: the foreign_key `author_#{Author.pk_name}' is already used/)
    end
  end
end
