require 'spec_helper'

describe 'join' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { |i| Post.create(:author => author, :title => i) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { |j| Comment.create(:post => author.posts[i], :body => j) } }.flatten }

  context 'joining on a belongs_to association' do
    it 'eq_join' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(1).times
      Comment.join(:post).each do |comment|
        comment.post.should == comments.select { |c| c == comment }.first.post
      end
    end

    context 'when using raw' do
      it 'eq_join and returns a join hash' do
        result = Comment.join(:post).raw.to_a
        result.map { |h| h['left'][Comment.pk_name.to_s] }.should == comments.map(&:pk_value)
        result.map { |h| h['right'][Post.pk_name.to_s] }.uniq.sort.should == posts.map(&:pk_value).sort
      end
    end
  end
end
