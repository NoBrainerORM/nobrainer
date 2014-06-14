require 'spec_helper'

describe 'dependents' do
  before { load_blog_models }

  let!(:author)   { Author.create  }
  let!(:posts)    { 2.times { Post.create(:author => author) } }
  let!(:comments) { 2.times { |i| 2.times { Comment.create(:post => author.posts[i]) } } }

  context 'when deleting an object with a has_many association' do
    before do
      Author.has_many :posts, :dependent => dependent_type
      Post.has_many :comments, :dependent => dependent_type
    end

    context 'when using a no dependent type' do
      let(:dependent_type) { nil }

      it 'does nothing' do
        author.destroy
        Post.count.should == 2
        Comment.count.should == 4
        Post.first.send("author_#{Author.pk_name}").should == author.pk_value
      end
    end

    context 'when using a delete dependent type' do
      let(:dependent_type) { :delete }

      it 'deletes the child documents' do
        author.destroy
        Post.count.should == 0
        Comment.count.should == 4
      end
    end

    context 'when using a destroy dependent type' do
      let(:dependent_type) { :destroy }

      it 'deletes the child documents' do
        author.destroy
        Post.count.should == 0
        Comment.count.should == 0
      end
    end

    context 'when using a nullify dependent type' do
      let(:dependent_type) { :nullify }

      it 'nullifies the child documents' do
        author.destroy
        Post.count.should == 2
        Comment.count.should == 4
        Post.first.send("author_#{Author.pk_name}").should == nil
        Comment.first.send("post_#{Post.pk_name}").should_not == nil
      end
    end

    context 'when using a restrict dependent type' do
      let(:dependent_type) { :restrict }

      it 'raises an exception' do
        expect { author.destroy }.to raise_error(NoBrainer::Error::ChildrenExist)
      end
    end
  end
end
