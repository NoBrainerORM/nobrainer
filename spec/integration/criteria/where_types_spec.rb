require 'spec_helper'

describe 'where types' do
  before { load_simple_document }
  before { SimpleDocument.field :field1, :type => Integer }
  before { SimpleDocument.create(:field1 => 123) }

  context 'when using badly typed queries' do
    it 'understands types' do
      expect { SimpleDocument.where(:field1 => "abc") }.to raise_error(NoBrainer::Error::InvalidType, "Field1 should be a integer")
      SimpleDocument.where(:field1 => 123).count.should == 1

      expect { SimpleDocument.where(:field1.in => ["123", "xxx"]) }.to raise_error(NoBrainer::Error::InvalidType, "Field1 should be a integer")
      SimpleDocument.where(:field1.in => ["123", "456"]).count.should == 1

      expect { SimpleDocument.where(:field1.in => ("a".."z")) }.to raise_error(NoBrainer::Error::InvalidType, "Field1 should be a integer")
      SimpleDocument.where(:field1.in => (1..200)).count.should == 1

      expect { SimpleDocument.where(:field1.not.in => ("a".."z")) }.to raise_error(NoBrainer::Error::InvalidType, "Field1 should be a integer")
      SimpleDocument.where(:field1.not.in => (1..200)).count.should == 0
    end

    context 'when using a belongs_to association' do
      before { load_blog_models }

      it 'understands types' do
        p = Post.create
        Comment.create(:post => p)

        expect { Comment.where(:post => Comment.new).count }.to raise_error(NoBrainer::Error::InvalidType, 'Post should be a post')
        Comment.where(:post => p).count.should == 1
        expect { Comment.where(:post.in => [p, Comment.new]).count }.to raise_error(NoBrainer::Error::InvalidType, 'Post should be a post')
        Comment.where(:post.in => [p]).count.should == 1
      end
    end
  end
end
