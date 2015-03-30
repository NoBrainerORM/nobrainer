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

    it 'is chainable' do
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
      expect { post.comments << Comment.new }.to raise_error(/frozen/)
    end
  end

  context 'when using =' do
    it 'raises' do
      expect { post.comments = [] }.to raise_error(/manually/)
    end
  end

  context 'when using scopes' do
    before { Post.has_many :comments, :scope => ->{ where(:body.gte 2).order_by(:body) } }
    let!(:comments) { 5.times.to_a.shuffle.map { |i| Comment.create(:body => i, :post => post) } }

    it 'is scopable' do
      post.comments.map(&:body).should == [2,3,4]
    end
  end
  
  context 'when primary_key is set' do
    let(:columnist) { Columnist.create(:employee_id => 9000) }
    let(:article)   { Article.create(:columnist => columnist) }
    
    it 'responds to and sets the target foreign key' do
      expect(article).to respond_to(:columnist_employee_id)
      expect(article).to respond_to(:columnist)
      expect(article.columnist_employee_id).to be == columnist.employee_id
      expect(article.columnist).to be == columnist
    end
  end
  
  context 'when class_name is set' do
    let(:article) { Article.create(slug: 'short-titled-article') }
    let!(:footnotes) { 2.times.map { |i| Footnote.create(:body => i, :article => article) } }
    
    it 'responds to and sets the target class' do
      expect(article).to respond_to(:notes)
      article.notes.to_a.should =~ footnotes
    end

    it 'responds to and sets the foreign key' do
      footnote = footnotes.first
      expect(footnote).to respond_to(:article_slug_url)
      expect(footnote).to respond_to(:article)
      expect(footnote.article_slug_url).to be == article.slug
      expect(footnote.article).to be == article
      expect(article).to respond_to(:notes)
      expect(article.notes.first).to be_a(Footnote) 
    end
  end
  
end
