# frozen_string_literal: true

require 'spec_helper'

describe 'eager_loading' do
  before { load_blog_models }

  let!(:author)   { Author.create! }
  let!(:posts)    do
    3.times.map { |i| Post.create!(:author => author, :title => i) }
  end
  let!(:comments) do
    3.times.map do |i|
      3.times.map do |j|
        Comment.create!(:post => author.posts[i], :body => j)
      end
    end.flatten
  end

  context 'when eager loading on a belongs_to association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.twice

      Comment.eager_load(:post).each do |comment|
        expect(comment.post).to eql(comments.select { |c| c == comment }.first.post)
      end
    end
  end

  context 'when eager loading on a has_many association' do
    it 'eagers load' do
      expect(NoBrainer).to receive(:run).and_call_original.twice

      Post.eager_load(:comments).each do |post|
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading nested associations' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(:posts => [:author, :comments]).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts)
      a.posts.each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading nested associations with multiple eager_load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(:posts => :author).eager_load(:posts => :comments).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts)
      a.posts.each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading after the fact' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(:posts => :comments).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts)
      a.posts.eager_load(:author).each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading after the fact on top of an existing eager load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(:posts => [:author, :comments]).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts)
      a.posts.eager_load(:comments).each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading after the fact on top of a cached criteria' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts)

      criteria = a.posts.eager_load(:comments)

      ([criteria.first] + criteria.to_a).each do |post|
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post })
      end
    end
  end

  context 'when eager loading nested associations with criterias' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(
        :posts => Post.where(:title.gte => 1).eager_load(
          :author,
          :comments => Comment.where(:body.gte => 1)
        )
      ).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts.select { |p| p.title >= 1 })

      a.posts.each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post && c.body >= 1 })
      end
    end
  end

  context 'when eager loading scoped associations' do
    before do
      Author.has_many :posts, :scope => ->{ where(:title.gte 1) }
      Post.has_many :comments, :scope => ->{ where(:body.gte 1) }
    end

    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.thrice

      a = Author.eager_load(:posts => [:author, :comments]).first

      expect(a).to eql(author)
      expect(a.posts.to_a).to eql(posts[1..2])

      a.posts.each do |post|
        expect(post.author).to eql(author)
        expect(post.comments.to_a).to eql(comments.select { |c| c.post == post }[1..2])
      end
    end
  end

  context 'when eager loading an array of docs with NoBrainer.eager_load' do
    it 'eager loads' do
      expect(NoBrainer).to receive(:run).and_call_original.twice

      comments = Comment.all.to_a

      comments += comments
      NoBrainer.eager_load(comments, :post)

      comments.each do |comment|
        expect(comment.post).to eql(comments.select { |c| c == comment }.first.post)
      end
    end
  end
end
