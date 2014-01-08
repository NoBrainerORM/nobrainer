require 'spec_helper'

describe 'eager_loading' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { |i| Post.create(:author => author, :title => i) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { |j| Comment.create(:post => author.posts[i], :body => j) } }.flatten }

  context 'when eager loading on a belongs_to association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Comment.preload(:post).each do |comment|
        comment.post.should == comments.select { |c| c == comment }.first.post
      end
    end
  end

  context 'when eager loading on a has_many association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Post.preload(:comments).each do |post|
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.preload(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations with multiple preload' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.preload(:posts => :author).preload(:posts => :comments).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading after the fact' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.preload(:posts => :comments).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.preload(:author).each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading after the fact on top of an existing eager load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.preload(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.preload(:comments).each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations with criterias' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.preload(:posts => Post.where(:title.gte => 1).preload(
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
