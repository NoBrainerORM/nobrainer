require 'spec_helper'

describe 'NoBrainer table_config' do
  before { load_simple_document }
  before { NoBrainer.drop! }
  after  { NoBrainer.drop! }
  before { NoBrainer::System::DBConfig.where(:name => /^test_db[0-9]/).delete_all }
  after  { NoBrainer::System::DBConfig.where(:name => /^test_db[0-9]/).delete_all }

  context 'when using the global wrapper' do
    it 'switches databases' do
      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.create
        SimpleDocument.count.should == 1
      end

      NoBrainer.run_with(:db => 'test_db2') do
        SimpleDocument.count.should == 0
        2.times { SimpleDocument.create }
        SimpleDocument.count.should == 2

        NoBrainer.run_with(:db => 'test_db1') do
          SimpleDocument.count.should == 1
        end

        SimpleDocument.count.should == 2
      end

      SimpleDocument.count.should == 0

      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.count.should == 1
        NoBrainer.drop!
      end

      NoBrainer.run_with(:db => 'test_db1') do
        SimpleDocument.count.should == 0
      end
    end
  end

  context 'when using table_config to switch tables' do
    before do
      SimpleDocument.table_config :name => ->{ @table }
    end

    it 'switches databases' do
      @table = 'table1'
      SimpleDocument.create
      SimpleDocument.count.should == 1

      @table = 'table2'
      SimpleDocument.count.should == 0
      2.times { SimpleDocument.create }
      SimpleDocument.count.should == 2

      @table = 'table1'
      SimpleDocument.count.should == 1

      NoBrainer.run { |r| r.table_list }.should =~ ['table1', 'table2']
    end
  end

  context 'when using table_config with symbols' do
    it 'converts names to strings' do
      SimpleDocument.table_config :name => :table1
      SimpleDocument.table_name.should == 'table1'
    end

    it 'converts lambda names to strings' do
      SimpleDocument.table_config :name => ->{ :table1 }
      SimpleDocument.table_name.should == 'table1'
    end
  end

  context 'when leaking criteria with run_with' do
    it 'raises' do
      c = NoBrainer.run_with(:db => 'hello') { SimpleDocument.all }
      expect { c.count }.to raise_error(/cannot be executed.*context/)
      NoBrainer.run_with(:db => 'hello') { c.count.should == 0 }
    end
  end

  context 'when specifying durability, replicas, shards, replicas_tags' do
    # XXX We can't test the replicas setting due to single server setup.
    # TODO The write_acks / durability settings are not working on < RethinkDB 2.1
    before { NoBrainer.configure { |c| c.table_options = { :shards => 2, :replicas => 1, :write_acks => :majority } } }
    before { define_class(:OtherModel) { include NoBrainer::Document } }

    it 'configures the table properly' do
      NoBrainer.sync_schema

      SimpleDocument.table_config.shards.count.should == 2
      # SimpleDocument.table_config.write_acks.should == 'majority'
      # SimpleDocument.table_config.durability.should == 'hard'

      SimpleDocument.table_config :durability => :soft, :shards => 3, :write_acks => :single
      NoBrainer.sync_schema

      SimpleDocument.table_config.shards.count.should == 3
      # SimpleDocument.table_config.write_acks.should == 'single'
      # SimpleDocument.table_config.durability.should == 'soft'

      OtherModel.table_config.shards.count.should == 2
      # OtherModel.table_config.write_acks.should == 'majority'
      # OtherModel.table_config.durability.should == 'hard'
    end
  end
end
