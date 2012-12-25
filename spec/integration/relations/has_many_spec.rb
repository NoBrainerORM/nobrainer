require 'spec_helper'

describe 'has_many' do
  before { load_blog_models }
  let!(:noise) { 2.times.map { |i| Comment.create(:body => i) } }

  let(:post) { Post.create }

  context 'when there are no comments' do
    it 'is empty' do
      post.comments.should be_empty
    end
  end

  context 'when there are many comments' do
    let!(:comments) { 2.times.map { |i| Comment.create(:body => i, :post => post) } }

    it 'returns these comments' do
      post.comments.to_a.should =~ comments
    end

    it 'is scopable' do
      post.comments.where(:body => 1).count.should == 1
    end
  end

  context 'when appending' do
    it 'persists elements' do
      post.comments << Comment.new
      post.comments << Comment.create
      post.comments.count.should == 2

      post.reload
      Comment.create(:post => post)
      post.comments.count.should == 3
    end
  end

  context 'when using =' do
    it 'destroys, and persists elements' do
      Comment.create(:post => post)
      post.comments.count.should == 1

      post.comments = [Comment.new, Comment.create]
      post.comments.count.should == 2
      post.reload
      post.comments.count.should == 2
    end
  end

  context 'when calling create' do
    it 'creates a child' do
      comment = post.comments.create(:body => 'ohai')
      Post.find(post.id).comments.first.should == comment
      Post.find(post.id).comments.first.body.should == 'ohai'
    end
  end

  context 'when calling create!' do
    context 'when the child is valid' do
      it 'creates a child' do
        comment = post.comments.create!(:body => 'ohai')
        Post.find(post.id).comments.first.should == comment
        Post.find(post.id).comments.first.body.should == 'ohai'
      end
    end

    context 'when the child is not valid' do
      it 'raises an exception' do
        Comment.validates :author, :presence => true
        expect { post.comments.create!(:body => 'ohai') }.
          to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end
  end

  context 'when calling build' do
    it 'build a child' do
      comment = post.comments.build(:body => 'ohai')
      Post.find(post.id).comments.first.should == nil
      comment.save
      Post.find(post.id).comments.first.should == comment
      Post.find(post.id).comments.first.body.should == 'ohai'
    end
  end
end
