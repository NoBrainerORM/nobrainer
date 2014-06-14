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

  context 'when the association is set, but is invalid' do
    let(:comment) { Comment.create("post_#{Post.pk_name}" => "000000000000000000000000") }
    it 'returns nil' do
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
end
