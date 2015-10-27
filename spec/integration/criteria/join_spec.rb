require 'spec_helper'

describe 'join' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 3.times.map { |i| Post.create(:author => author, :title => i) } }
  let!(:comments) { 3.times.map { |i| 3.times.map { |j| Comment.create(:post => author.posts[i], :body => j) } }.flatten }

  before { Post.create(:author => nil)}
  before { Post.create }
  before { Comment.create(:post => nil)}
  before { Comment.create }

  before { Post.create }
  before { Comment.create }

  before { expect(NoBrainer).to receive(:run).and_call_original.exactly(1).times }

  context 'joining on a belongs_to association' do
    it 'joins' do
      Comment.join(:post).map { |c| [c, c.post] }.should =~ comments.map { |c| [c, c.post] }
    end

    context 'when getting a nil element' do
      it 'returns nil' do
        Comment.join(:post).last.should == nil
      end
    end

    context 'when using raw' do
      it 'joins and returns a join hash' do
        result = Comment.join(:post).raw.to_a
        result.map { |h| h[Comment.pk_name.to_s] }.should == comments.map(&:pk_value)
        result.map { |h| h['post'][Post.pk_name.to_s] }.uniq.sort.should == posts.map(&:pk_value).sort
      end
    end
  end

  context 'when joining on a has_many association' do
    it 'joins' do
      Post.join(:comments).map { |p| [p, p.comments.first] }.should =~
        posts.flat_map { |p| comments.select { |c| c.post == p }.map { |c| [p, c] } }
    end
  end

  context 'when joining with criteria' do
    it 'joins' do
      Post.join(:comments => Comment.where(:body => 1)).map { |p| [p, p.comments.first] }.should =~
        posts.flat_map { |p| comments.select { |c| c.post == p && c.body == 1 }.map { |c| [p, c] } }
    end
  end

  context 'when joining on multiple associations' do
    it 'joins' do
      Post.join(:comments, :author).map { |p| [p.author, p, p.comments.first] }.should =~
        posts.flat_map { |p| comments.select { |c| c.post == p }.map { |c| [author, p, c] } }
    end
  end

  context 'when joining on recursive associations' do
    it 'joins' do
      Author.join(:posts => :comments).map { |a| [a, a.posts.first, a.posts.first.comments.first] }.should =~
        posts.flat_map { |p| comments.select { |c| c.post == p }.map { |c| [author, p, c] } }
    end
  end

  context 'when joining on through associations' do
    before { Author.has_many :comments, :through => :posts }
    it 'fails' do
      expect { Author.join(:comments).to_a }.to raise_error(/join().*through/)
    end
  end
end
