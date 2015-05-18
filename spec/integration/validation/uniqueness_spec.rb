require 'spec_helper'

describe 'uniqueness validator' do
  before { load_simple_document }

  context 'with validates_uniqueness_of' do
    before { SimpleDocument.validates_uniqueness_of :field1 }
    let!(:doc) { SimpleDocument.create(:field1 => 'ohai') }

    it 'cannot save a non-unique value' do
      doc2 = SimpleDocument.new field1: 'ohai'
      doc2.valid?.should == false
      expect { doc2.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'uses the proper locale' do
      doc2 = SimpleDocument.new field1: 'ohai'
      doc2.valid?.should == false
      doc2.errors.full_messages.first.should == "Field1 is already taken"
    end

    it 'validates only when the field changes' do
      SimpleDocument.create({:field1 => 'ohai', :field2 => 'new'}, :validate => false)
      doc2 = SimpleDocument.where(:field2 => 'new').first
      doc2.valid?.should == true
      doc2.field1 = 'hello'
      doc2.valid?.should == true
      doc2.save
      doc2.field1 = 'ohai'
      doc2.valid?.should == false
    end
  end

  context 'without a scope' do
    before { SimpleDocument.validates :field1, :uniqueness => true }
    let!(:doc) { SimpleDocument.create(:field1 => 'ohai') }

    it 'can save an existing document' do
      doc.valid?.should == true
      doc.save?.should == true
    end

    it 'cannot save a non-unique value' do
      doc2 = SimpleDocument.new field1: 'ohai'
      doc2.valid?.should == false
      expect { doc2.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save a unique value' do
      doc2 = SimpleDocument.new field1: 'okbai'
      doc2.valid?.should == true
      doc2.save?.should == true
    end
  end

  context 'with a default scope' do
    before do
      SimpleDocument.class_eval do
        validates :field1, :uniqueness => true
        default_scope where(:field2 => 'hello')
      end
    end

    it 'does not use the default scope' do
      SimpleDocument.create(field1: 'hello')
      SimpleDocument.new(field1: 'hello').valid?.should == false
    end
  end

  context 'with a single scope' do
    before { SimpleDocument.validates :field1, :uniqueness => {scope: :field2} }

    let!(:doc) { SimpleDocument.create(:field1 => 'ohai', :field2 => 'there') }

    it 'cannot save a non-unique value in the same scope' do
      doc2 = SimpleDocument.new field1: 'ohai', field2: 'there'
      doc2.valid?.should == false
      expect { doc2.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save a unique value in the same scope' do
      doc2 = SimpleDocument.new field1: 'okbai', field2: 'there'
      doc2.valid?.should == true
      doc2.save?.should == true
    end

    it 'can save a non-unique value in a different scope' do
      doc2 = SimpleDocument.new field1: 'ohai', field2: 'now'
      doc2.valid?.should == true
      doc2.save?.should == true
    end

    it 'validates only when the field changes' do
      doc2 = SimpleDocument.new(:field1 => 'ohai', :field2 => nil)
      doc2.clear_dirtiness
      doc2.valid?.should == true
      doc2.field2 = 'there'
      doc2.valid?.should == false
    end
  end

  context 'with multiple scopes' do
    before { SimpleDocument.validates :field1, :uniqueness => {scope: [:field2, :field3]} }

    let!(:doc) { SimpleDocument.create(:field1 => 'ohai', :field2 => 'there', :field3 => 'bob') }

    it 'cannot save a non-unique value in all of the same scopes' do
      doc2 = SimpleDocument.new field1: 'ohai', field2: 'there', field3: 'bob'
      doc2.valid?.should == false
      expect { doc2.save }.to raise_error(NoBrainer::Error::DocumentInvalid)
    end

    it 'can save a unique value in all of the same scopes' do
      doc2 = SimpleDocument.new field1: 'okbai', field2: 'there', field3: 'bob'
      doc2.valid?.should == true
      doc2.save?.should == true
    end

    it 'can save a non-unique value when not all of the scopes match' do
      doc2 = SimpleDocument.new field1: 'ohai', field2: 'there', field3: 'jimmy'
      doc2.valid?.should == true
      doc2.save?.should == true
      doc3 = SimpleDocument.new field1: 'ohai', field2: 'now', field3: 'bob'
      doc3.valid?.should == true
      doc3.save?.should == true
    end
  end

  context 'with polymorphic classes' do
    before { load_polymorphic_models }

    context 'when applied on the parent' do
      before { Parent.validates :parent_field, :uniqueness => true }
      let!(:parent_doc) { Parent.create(:parent_field => 'ohai') }

      it 'validates in the scope of the parent' do
        Parent.new(:parent_field => 'ohai').valid?.should == false
        Child.new(:parent_field => 'ohai').valid?.should == false
        GrandChild.new(:parent_field => 'ohai').valid?.should == false
      end
    end

    context 'when applied on the child' do
      before { Child.validates :parent_field, :uniqueness => true }
      let!(:parent_doc) { Parent.create(:parent_field => 'ohai') }

      it 'validates in the scope of the child' do
        Parent.new(:parent_field => 'ohai').valid?.should == true
        Child.new(:parent_field => 'ohai').valid?.should == false
        GrandChild.new(:parent_field => 'ohai').valid?.should == false
      end
    end
  end

  context 'when using a distributed lock' do
    before do
      define_class :Lock do
        singleton_class.send(:attr_accessor, :locked_keys)
        singleton_class.send(:attr_accessor, :unlocked_keys)

        def initialize(key)
          @key = key
        end

        def lock
          self.class.locked_keys << @key
        end

        def unlock
          self.class.unlocked_keys << @key
        end
      end

      NoBrainer.configure do |config|
        config.distributed_lock_class = Lock
      end
    end

    before do
      SimpleDocument.validates_uniqueness_of :field1
      SimpleDocument.validates_uniqueness_of :field3
      SimpleDocument.validates_uniqueness_of :field2
    end

    let(:doc) { SimpleDocument.new(:field1 => 'ohai', :field2 => 'blah', :field3 => nil) }

    it 'locks things around' do
      Lock.locked_keys = []
      Lock.unlocked_keys = []
      doc.valid?.should == true
      Lock.locked_keys.should == []
      Lock.unlocked_keys.should == []

      Lock.locked_keys = []
      Lock.unlocked_keys = []
      doc.save
      Lock.locked_keys.should == ["nobrainer:#{NoBrainer.connection.parsed_uri[:db]}:simple_documents:field1:ohai",
                                  "nobrainer:#{NoBrainer.connection.parsed_uri[:db]}:simple_documents:field2:blah",
                                  "nobrainer:#{NoBrainer.connection.parsed_uri[:db]}:simple_documents:field3:nil"]
      Lock.unlocked_keys.should == Lock.locked_keys.reverse

      Lock.locked_keys = []
      Lock.unlocked_keys = []
      doc.update(:field3 => 'hello', :field1 => nil)
      Lock.locked_keys.should == ["nobrainer:#{NoBrainer.connection.parsed_uri[:db]}:simple_documents:field1:nil",
                                  "nobrainer:#{NoBrainer.connection.parsed_uri[:db]}:simple_documents:field3:hello"]
      Lock.unlocked_keys.should == Lock.locked_keys.reverse
    end

    it 'locks things around the before_save/update/create callbacks' do
      SimpleDocument.before_validation do
        Lock.locked_keys.should_not == []
        Lock.unlocked_keys.reverse.should == []
      end

      cb = proc do |doc|
        Lock.locked_keys.should_not == []
        Lock.unlocked_keys.reverse.should_not == []
      end
      SimpleDocument.after_save(&cb)
      SimpleDocument.after_create(&cb)
      SimpleDocument.after_update(&cb)

      Lock.locked_keys = []
      Lock.unlocked_keys = []
      doc.save

      Lock.locked_keys = []
      Lock.unlocked_keys = []
      doc.update(:field3 => 'hello', :field1 => nil)
    end

    context 'when using incorrect type' do
      before { SimpleDocument.field :field1, :type => Integer, :uniq => true }

      it 'does not raise' do
        SimpleDocument.new(:field1 => 1).valid?.should == true
        SimpleDocument.new(:field1 => 'x').valid?.should == false
      end
    end
  end
end
