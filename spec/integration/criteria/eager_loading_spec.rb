require 'spec_helper'

describe 'eager_loading' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { |i| Post.create(:author => author, :title => i) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { |j| Comment.create(:post => author.posts[i], :body => j) } }.flatten }

  context 'when eager loading on a belongs_to association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Comment.eager_load(:post).each do |comment|
        comment.post.should == comments.select { |c| c == comment }.first.post
      end
    end
  end

  context 'when eager loading on a has_many association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Post.eager_load(:comments).each do |post|
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.eager_load(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations with multiple eager_load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.eager_load(:posts => :author).eager_load(:posts => :comments).first
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
      a = Author.eager_load(:posts => :comments).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.eager_load(:author).each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading after the fact on top of an existing eager load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.eager_load(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts
      a.posts.eager_load(:comments).each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading after the fact on top of a cached criteria' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.first
      a.should == author
      a.posts.to_a.should == posts
      criteria = a.posts.eager_load(:comments)
      ([criteria.first] + criteria.to_a).each do |post|
        post.comments.to_a.should == comments.select { |c| c.post == post }
      end
    end
  end

  context 'when eager loading nested associations with criterias' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.eager_load(:posts => Post.where(:title.gte => 1).eager_load(
                            :author, :comments => Comment.where(:body.gte => 1))).first
      a.should == author
      a.posts.to_a.should == posts.select { |p| p.title >= 1 }
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post && c.body >= 1 }
      end
    end
  end

  context 'when eager loading scoped associations' do
    before { Author.has_many :posts, :scope => ->{ where(:title.gte 1) } }
    before { Post.has_many :comments, :scope => ->{ where(:body.gte 1) } }

    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(3).times
      a = Author.eager_load(:posts => [:author, :comments]).first
      a.should == author
      a.posts.to_a.should == posts[1..2]
      a.posts.each do |post|
        post.author.should == author
        post.comments.to_a.should == comments.select { |c| c.post == post }[1..2]
      end
    end
  end

  context 'when eager loading an array of docs with NoBrainer.eager_load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      comments = Comment.all.to_a
      comments = comments + comments
      NoBrainer.eager_load(comments, :post)
      comments.each do |comment|
        comment.post.should == comments.select { |c| c == comment }.first.post
      end
    end
  end
end
