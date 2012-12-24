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
end
