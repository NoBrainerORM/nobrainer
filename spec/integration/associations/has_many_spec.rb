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
    before { load_columnist_models }
    let(:columnist) { Columnist.create(:employee_id => 9000) }
    let(:article)   { Article.create(:columnist => columnist) }

    it 'responds to and sets the target foreign key' do
      article.columnist_employee_id.should == columnist.employee_id
      article.columnist.should== columnist
    end
  end

  context 'when class_name is set' do
    before { load_columnist_models }
    let(:article) { Article.create(slug: 'short-titled-article') }
    let!(:footnotes) { 2.times.map { |i| Footnote.create(:body => i, :article => article) } }

    it 'responds to and sets the target class' do
      article.notes.to_a.should =~ footnotes
    end

    it 'responds to and sets the foreign key' do
      footnote = footnotes.first
      footnote.article_slug_url.should == article.slug
      footnote.article.should == article
    end
  end

  context 'when a custom primary key model is used' do
    before { load_album_models }

    let(:album)    { Album.create(:slug => 'slug') }
    let!(:pictures) { 2.times.map { Picture.create(:album => album) } }

    it 'should use the primary key properly' do
      album.pictures.to_a.should =~ pictures
    end
  end

  context 'when model is created inside module' do
    it 'should find association' do
      define_class('ModuleA::Model') do
        include NoBrainer::Document
      end
      define_class('ModuleA::Model2') do
        include NoBrainer::Document
        has_many :models
      end
    end

    it 'should find association if associated model is toplevel class ' do
      define_class('Model') do
        include NoBrainer::Document
      end
      define_class('ModuleA::Model2') do
        include NoBrainer::Document
        has_many :models
      end
    end

    it 'should raise error if associated model is in different module' do
      define_class('ModuleA::Model') do
        include NoBrainer::Document
      end
      expect do
        model_with_has_many_association = define_class('ModuleC::Model2') do
          include NoBrainer::Document
          has_many :models
        end
        model_with_has_many_association.new.models
      end.to raise_error NameError
    end
  end
end
