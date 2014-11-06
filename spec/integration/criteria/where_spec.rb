require 'spec_helper'

describe 'where' do
  before { load_simple_document }

  let!(:doc1) { SimpleDocument.create(:field1 => 'ohai') }
  let!(:doc2) { SimpleDocument.create(:field1 => 'hello') }
  let!(:doc3) { SimpleDocument.create(:field1 => 'hola') }

  context 'when passing empty conditions' do
    it 'filters documents' do
      SimpleDocument.where(:field1 => 'ohai').where({}).count.should == 1

      SimpleDocument.where({}).count.should == 3
      SimpleDocument.where({},{}).count.should == 3
      SimpleDocument.where([]).count.should == 3
      SimpleDocument.where([],[]).count.should == 3
      SimpleDocument.where().count.should == 3

      SimpleDocument.where(:field1 => 'ohai').where({}).count.should == 1
      SimpleDocument.where(:field1 => 'ohai').where({},{}).count.should == 1
      SimpleDocument.where(:field1 => 'ohai').where([]).count.should == 1
      SimpleDocument.where(:field1 => 'ohai').where([],[]).count.should == 1
      SimpleDocument.where(:field1 => 'ohai').where().count.should == 1
    end
  end

  context 'when passing a hash of attributes' do
    it 'filters documents' do
      SimpleDocument.where(:field1 => 'ohai').count.should == 1
    end
  end

  context 'when passing a block' do
    it 'filters documents' do
      SimpleDocument.where {|doc| doc[:field1].eq('ohai')}.count.should == 1
    end

    it 'filters documents with a regex (in string format)' do
      SimpleDocument.where {|doc| doc[:field1].match('h')}.count.should == 3
      SimpleDocument.where {|doc| doc[:field1].match('hola')}.count.should == 1
    end
  end

  context 'when passing a field that does not exist' do
    it 'filters documents without yelling' do
      SimpleDocument.where(:field_new => 'hi').count.should == 0
      SimpleDocument.field :field_new
      SimpleDocument.first.update(:field_new => 'hi')
      SimpleDocument.where(:field_new => 'hi').count.should == 1
    end

    it 'does not return documents that have the field set to nil' do
      SimpleDocument.where(:field_new => nil).count.should == 0
      SimpleDocument.field :field_new
      SimpleDocument.first.update(:field_new => 'hi')
      SimpleDocument.where(:field_new => 'hi').count.should == 1
      SimpleDocument.first.update(:field_new => nil)
      SimpleDocument.where(:field_new => nil).count.should == 1
    end
  end

  context 'when passing a regex as a condition' do
    it 'can filter using that regex /h/' do
      SimpleDocument.where(:field1 => /h/).count.should == 3
    end

    it 'can filter using that regex /^h/' do
      SimpleDocument.where(:field1 => /^h/).count.should == 2
    end

    it 'can filter using that regex with a chained where clause' do
      SimpleDocument.where(:field1 => /h/).where(:field1 => 'ohai').count.should == 1
    end

    it 'can filter using that regex with a chained where clause in alternate order' do
      SimpleDocument.where(:field1 => 'ohai').where(:field1 => /h/).count.should == 1
    end

    it 'can filter using that regex and normal syntax combined' do
      SimpleDocument.create(:field2 => 'sayonara')
      SimpleDocument.where(:field1 => 'hola').first.update(:field2 => 'sayonara')
      SimpleDocument.where(:field1 => /h/, :field2 => 'sayonara').count.should == 1
      SimpleDocument.where(:field1 => /o/, :field2 => /o/).count.should == 1
    end

    it 'should only find documents that match the regex' do
      SimpleDocument.where(:field1 => /x/).count.should == 0
    end
  end
end

describe 'complex where queries' do
  before { load_simple_document }

  context 'when using numeric values' do
    before { 10.times { |i| SimpleDocument.create(:field1 => (i+1)) } }

    context 'when using comparison operators' do
      it 'filters documents' do
        SimpleDocument.where(:field1.gt  => 7).count.should == 3
        SimpleDocument.where(:field1.ge  => 7).count.should == 4
        SimpleDocument.where(:field1.gte => 7).count.should == 4

        SimpleDocument.where(:field1.lt  => 7).count.should == 6
        SimpleDocument.where(:field1.le  => 7).count.should == 7
        SimpleDocument.where(:field1.lte => 7).count.should == 7
      end
    end

    context 'when using ranges' do
      it 'filters documents' do
        SimpleDocument.where(:field1 => (3..8)).count.should == 6
        SimpleDocument.where(:field1.in => (3..8)).count.should == 6
      end
    end

    context 'when using in' do
      it 'filters documents' do
        SimpleDocument.where(:field1.in => [3,5,9,33]).count.should == 3
      end
    end

    context 'when using nin' do
      it 'filters documents' do
        SimpleDocument.where(:field1.nin => [3,5,9,33]).count.should == 7
      end
    end

    context 'when using or' do
      it 'filters documents' do
        SimpleDocument.where(:or => [{:field1 => 3}, {:field1 => 7}, {:field1 => 33}]).count.should == 2
      end
    end

    context 'when using and' do
      it 'filters documents' do
        SimpleDocument.create(:field1 => 1, :field2 => 456)
        SimpleDocument.where(:and => [{:field1 => 1}, {:field2 => 456}]).count.should == 1
      end
    end

    context 'when using not' do
      it 'filters documents' do
        SimpleDocument.where(:field1.ne  => 3).count.should == 9
        SimpleDocument.where(:field1.not => 3).count.should == 9
        SimpleDocument.where(:field1.not => (3..8)).count.should == 4
      end
    end

    context 'when using lambdas' do
      it 'filters documents' do
        SimpleDocument.where { |doc| (doc[:field1] * 2).eq(16) }.count.should == 1
      end
    end

    context 'when using a keyword without =>' do
      it 'filters documents' do
        SimpleDocument.where(:field1.in [3,5,9,33]).count.should == 3
      end
    end

    context 'when using defined' do
      before { SimpleDocument.delete_all }
      let!(:doc1) { SimpleDocument.create(:field1 => 'hey') }
      let!(:doc2) { SimpleDocument.create(:field2 => 'hey') }
      let!(:doc3) { SimpleDocument.create(:field1 => 'hey', :field2 => 'hey') }

      it 'filters documents' do
        SimpleDocument.where(:field1.defined => false).count.should == 1
        SimpleDocument.where(:field1.defined => true).count.should == 2
        SimpleDocument.where(:field2.defined => false).count.should == 1
        SimpleDocument.where(:field2.defined => true).count.should == 2

        SimpleDocument.where(:field1.defined => true,
                             :field2.defined => false).first.should == doc1
        SimpleDocument.where(:field1.defined => false,
                             :field2.defined => true).first.should == doc2
        SimpleDocument.where(:field1.defined => true,
                             :field2.defined => true).first.should == doc3
      end
    end
  end

  context 'when using dates' do
    let(:time) { Time.now }
    before { 10.times { |i| SimpleDocument.create(:field1 => time + i) } }

    it 'filters documents' do
      SimpleDocument.where(:field1.gte => time + 7).count.should == 3
      SimpleDocument.where(:field1.lt  => time + 7).count.should == 7
      SimpleDocument.where(:field1.gte => time.utc + 7).count.should == 3
      SimpleDocument.where(:field1.lt  => time.utc + 7).count.should == 7
    end
  end

  context 'when using a belongs_to association' do
    before { load_blog_models }

    it 'converts to a foreign key search' do
      post1 = Post.create
      post2 = Post.create
      c1 = Comment.create(:post => post1)
      c2 = Comment.create(:post => post2)
      Comment.create

      Comment.count.should == 3
      Comment.where(:post => post1).first.should == c1
      Comment.where(:post => post2).first.should == c2
      Comment.where(:post.in => [post1, post2]).count.should == 2
    end
  end
end
