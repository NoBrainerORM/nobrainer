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

    it 'caches the reverse association' do
      expect(NoBrainer).to receive(:run).and_call_original.exactly(2).times
      Post.first.comments.each do |comment|
        comment.post.should == post
      end
    end
  end

  context 'when appending' do
    it 'raises' do
      expect { post.comments << Comment.new }.to raise_error
    end
  end

  context 'when using =' do
    it 'raises' do
      expect { post.comments = [] }.to raise_error
    end
  end
end
