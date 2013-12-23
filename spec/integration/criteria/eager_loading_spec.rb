require 'spec_helper'

describe 'eager_loading' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { Post.create(:author => author) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { Comment.create(:post => author.posts[i]) } }.flatten }

  context 'when eager loading on a belongs_to relation' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Comment.includes(:post).each do |comment|
        comment.post.should == comments.select { |c| c == comment }.first.post
      end
    end
  end

  context 'when eager loading on a has_many relation' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Post.includes(:comments).each do |post|
        post.comments.to_a.should =~ comments.select { |c| c.post == post }
      end
    end
  end
end
