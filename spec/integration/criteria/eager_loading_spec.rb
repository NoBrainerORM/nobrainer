require 'spec_helper'

describe 'eager_loading' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { |i| Post.create(:author => author, :title => i) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { |j| Comment.create(:post => author.posts[i], :body => j) } }.flatten }

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
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested relations' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(4).times
      a = Author.includes(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested relations with criterias' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(4).times
      a = Author.includes(:posts => Post.where(:title.gte => 1).includes(
                            :author, :comments => Comment.where(:body.gte => 1))).first
      a.should == author
      a.posts.to_a.should == posts.select { |p| p.title >= 1 }
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post && c.body >= 1 }
      end
    end
  end
end
