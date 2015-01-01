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
    context 'when not using dynamic attributes' do
      it 'raises' do
        expect { SimpleDocument.where(:field_new => 'hi').count } \
          .to raise_error(NoBrainer::Error::UnknownAttribute, "`field_new' is not a declared attribute of SimpleDocument")

        SimpleDocument.field :field_new
        SimpleDocument.first.update(:field_new => 'hi')
        SimpleDocument.where(:field_new => 'hi').count.should == 1
      end
    end

    context 'when using an index' do
      before { SimpleDocument.index :field_new }
      before { NoBrainer.sync_indexes }
      after  { NoBrainer.drop! }

      it 'does not raises' do
        SimpleDocument.where(:field_new => 'hi').count.should == 0
      end
    end

    context 'when using dynamic attributes' do
      before { SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes) }

      it 'does not raises' do
        SimpleDocument.where(:field_new => 'hi').count.should == 0
      end
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

      context 'when detecting a possible misuse of or' do
        it 'does not filter documents' do
          expect { SimpleDocument.where(:or => [:field1 => 3, :field1 => 7, :field1 => 33]).count }.to raise_error(/single hash element/)
        end
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

      context 'when using types' do
        before { SimpleDocument.field :field1, :type => String }

        it 'filters documents' do
          expect { SimpleDocument.where(:field1.defined => nil).count }.to raise_error(NoBrainer::Error::InvalidType)
          SimpleDocument.where(:field1.defined => true).count.should == 2
          SimpleDocument.where(:field1.defined => 't').count.should == 2
          SimpleDocument.where(:field2.defined => 'FaLse').count.should == 1
        end
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

  context 'when using betweens' do
    before do
      SimpleDocument.index :field1
      NoBrainer.sync_indexes
    end
    after { NoBrainer.drop! }

    context 'when using regular values' do
      before { 10.times.map { |i| SimpleDocument.create(:field1 => i+1) } }

      it 'uses the index' do
        SimpleDocument.where(:field1 => (3..8)).count.should == 6
        SimpleDocument.where(:field1.in => (3..8)).count.should == 6
        SimpleDocument.where(:field1.in => [3,5,9,33]).count.should == 3

        SimpleDocument.where(:field1 => (3..8)).where_indexed?.should == true
        SimpleDocument.where(:field1.in => (3..8)).where_indexed?.should == true
        SimpleDocument.where(:field1.in => [3,5,9,33]).where_indexed?.should == true

        SimpleDocument.where(:field1.gt => 7).count.should == 3
        SimpleDocument.where(:field1.ge => 7).count.should == 4
        SimpleDocument.where(:field1.lt => 7).count.should == 6
        SimpleDocument.where(:field1.le => 7).count.should == 7
        SimpleDocument.where(:field1.gt => 4, :field1.lt => 6).count.should == 1
        SimpleDocument.where(:field1.ge => 4, :field1.le => 6).count.should == 3
        SimpleDocument.where(:field1.gt => 4, :field1.gte => 2, :field1.lt => 6, :field1.lte => 8).count.should == 1

        SimpleDocument.where(:field1.gt => 7).where_indexed?.should == true
        SimpleDocument.where(:field1.ge => 7).where_indexed?.should == true
        SimpleDocument.where(:field1.lt => 7).where_indexed?.should == true
        SimpleDocument.where(:field1.le => 7).where_indexed?.should == true
        SimpleDocument.where(:field1.gt => 4, :field1.lt => 6).where_indexed?.should == true
        SimpleDocument.where(:field1.ge => 4, :field1.le => 6).where_indexed?.should == true
        SimpleDocument.where(:field1.gt => 4, :field1.gte => 2, :field1.lt => 6, :field1.lte => 8).where_indexed?.should == true
      end
    end

    context 'when using dates' do
      let(:time) { Time.now }
      before { 10.times { |i| SimpleDocument.create(:field1 => time + i) } }

      it 'uses the index' do
        SimpleDocument.where(:field1.gte => time + 7).count.should == 3
        SimpleDocument.where(:field1.lt  => time + 7).count.should == 7
        SimpleDocument.where(:field1.gte => time.utc + 7).count.should == 3
        SimpleDocument.where(:field1.lt  => time.utc + 7).count.should == 7
      end
    end
  end

  context 'when using :or' do
    before do
      SimpleDocument.index :field1
      SimpleDocument.index :field2
      NoBrainer.sync_indexes
    end
    after { NoBrainer.drop! }

    let!(:docs) { 10.times.map { |i| SimpleDocument.create(:field1 => i, :field2 => i, :field3 => i) } }

    it 'uses indexes when all clauses can be indexed' do
      SimpleDocument.where(:or => [{:field1 => 1}, {:field3 => 3}]).where_indexed?.should == false
      criteria = SimpleDocument.where(:or => [{:field1 => 1}, {:field1 => 3}, {:field2 => 4}]).order_by(:field1 => :desc)
      criteria.to_a.should == [docs[4], docs[3], docs[1]]
      criteria.where_indexed?.should == true
      criteria.where_index_name.should =~ [:field1, :field2]
    end

    it 'uses indexes even when clauses are partially indexable' do
      criteria = SimpleDocument.where(:or => [{:field1 => 1, :field2 => 3}, {:field1 => 1}, {:field2 => 4}]).order_by(:field1 => :desc)
      criteria.to_a.should == [docs[4], docs[1]]
      criteria.where_indexed?.should == true
      criteria.where_index_name.should =~ [:field1, :field1, :field2]
    end

    it 'returns distinct elements' do
      SimpleDocument.where(:or => [{:field1 => 1}, {:field2 => 1}]).count.should == 1
    end
  end

  context 'when using :or and multi indexes' do
    before do
      SimpleDocument.index :field1, :multi => true
      SimpleDocument.index :field2, :multi => true
      NoBrainer.sync_indexes
    end
    after { NoBrainer.drop! }

    let!(:docs) { 10.times.map { |i| SimpleDocument.create(:field1 => [i], :field2 => [i], :field3 => [i]) } }

    it 'uses indexes when all clauses can be indexed' do
      SimpleDocument.where(:or => [{:field1.any => 1}, {:field3.any => 3}]).where_indexed?.should == false
      criteria = SimpleDocument.where(:or => [{:field1.any => 1}, {:field1.any => 3}, {:field2.any => 4}]).order_by(:field1 => :desc)
      criteria.to_a.should == [docs[4], docs[3], docs[1]]
      criteria.where_indexed?.should == true
      criteria.where_index_name.should =~ [:field1, :field2]
    end

    it 'uses indexes even when clauses are partially indexable' do
      criteria = SimpleDocument.where(:or => [{:field1.any => 1, :field2.any => 3}, {:field1.any => 1}, {:field2.any => 4}]).order_by(:field1 => :desc)
      criteria.to_a.should == [docs[4], docs[1]]
      criteria.where_indexed?.should == true
      criteria.where_index_name.should =~ [:field1, :field1, :field2]
    end

    it 'returns distinct elements' do
      SimpleDocument.where(:or => [{:field1.any => 1}, {:field2.any => 1}]).count.should == 1
    end
  end

  context 'when using any' do
    before { SimpleDocument.create(:field1 => (1..10).to_a) }
    before { SimpleDocument.create(:field1 => (5..10).to_a) }
    before { SimpleDocument.create(:field1 => (7..10).to_a) }
    before { SimpleDocument.create(:field1 => (20..30).to_a) }

    shared_examples_for "queries using any" do
      it "applies filter to any element" do
        SimpleDocument.where(:field1.any => 6).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 2
        SimpleDocument.where(:field1.any.lt => 8).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 3
        SimpleDocument.where(:field1.any.lt => 2).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 1
        SimpleDocument.where(:field1.any.in => (0..6)).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 2
        SimpleDocument.where(:field1.any.in => [4,6]).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 2
        SimpleDocument.where(:field1.any.lt => 8).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 3
        SimpleDocument.where({:field1.any => 6}, {:field1.any => 20}).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 0
        SimpleDocument.where(:field1.any.gt => 6, :field1.any.lt => 23).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 4
        SimpleDocument.where(:field1.any.gte => 8, :field1.any.lte => 3).tap { |c| c.where_indexed?.should == should_use_index }.count.should == 1
      end
    end

    context 'when not using an index' do
      let(:should_use_index) { false }
      it_should_behave_like "queries using any"
    end

    context 'when using an index' do
      before { SimpleDocument.index :field1, index_options }
      before { NoBrainer.sync_indexes }
      after  { NoBrainer.drop! }

      context 'when using a multi index' do
        let(:index_options) { { :multi => true } }
        let(:should_use_index) { true }
        it_should_behave_like "queries using any"
      end

      context 'when using a regular index' do
        let(:index_options) { {} }
        let(:should_use_index) { false }
        it_should_behave_like "queries using any"
      end
    end
  end

  context 'when using all' do
    before { SimpleDocument.create(:field1 => [2,2,2]) }
    before { SimpleDocument.create(:field1 => (1..10).to_a) }
    before { SimpleDocument.create(:field1 => (5..10).to_a) }
    before { SimpleDocument.create(:field1 => (7..10).to_a) }

    it "applies filter to all element" do
      SimpleDocument.where(:field1.all.gte => 5).count.should == 2
      SimpleDocument.where(:field1.all => 2).count.should == 1
    end
  end

  context 'when using geo' do
    before do
      define_class :City do
        include NoBrainer::Document
        field :location, :type => NoBrainer::Geo::Point
      end
    end
    let!(:nyc)    { City.create(:location => [40.79, -73.97]) }
    let!(:paris)  { City.create(:location => [48.87, 2.28]) }
    let!(:boston) { City.create(:location => [42.30,-71.03]) }

    shared_examples_for 'near queries' do
      it 'finds nearest points' do
        City.where(:location.near => {:point => nyc.location, :max_distance => 300_000}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc]
        City.where(:location.near => {:point => nyc.location, :max_distance => 350_000}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc, boston]
        City.where(:location.near => {:point => nyc.location, :max_distance => 350, :unit => 'km'}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc, boston]
        City.where(:location.near => {:point => nyc.location, :max_distance => 300, :unit => 'km'}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc]
        City.where(:location.near => {:point => nyc.location, :max_distance => 300, :unit => 'mi'}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc, boston]
        City.where(:location.near => {:point => [48.87, 2.28], :max_distance => 1000}).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [paris]
      end
    end

    shared_examples_for 'intersect queries' do
      it 'finds intersecting queries' do
        City.where(:location.intersects => NoBrainer::Geo::Circle.new(nyc.location, :radius => 300_000)).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc]
        City.where(:location.intersects => NoBrainer::Geo::Circle.new(nyc.location, :radius => 350_000)).tap { |c| c.where_indexed?.should == should_use_index }.to_a.should =~ [nyc, boston]
      end
    end

    context 'when not using an index' do
      let(:should_use_index) { false }
      it_should_behave_like 'near queries'
      it_should_behave_like 'intersect queries'
    end

    context 'when using an index' do
      let(:should_use_index) { true }
      before { City.index :location }
      before { NoBrainer.sync_indexes }
      after  { NoBrainer.drop! }

      it_should_behave_like 'near queries'
      it_should_behave_like 'intersect queries'
    end
  end
end
