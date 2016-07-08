require 'spec_helper'

describe "NoBrainer query runner" do
  before { load_simple_document }
  before { SimpleDocument.create }

  describe 'run' do
    it 'takes an argument' do
      NoBrainer.run(SimpleDocument.to_rql.count).should == 1
    end

    it 'takes a block with r as an argument' do
      NoBrainer.run { |r| r.table('simple_documents').count }.should == 1
    end
  end

  unless ENV['EM'] # see https://github.com/rethinkdb/rethinkdb/issues/5929
    describe 'run_with' do
      it 'passes down options to r.run()' do
        NoBrainer.run_with(:profile => true) do
          SimpleDocument.raw.count.keys.should include "profile"
        end
      end
    end

    describe 'run_options' do
      before { NoBrainer.configure { |c| c.run_options = {:profile => true} } }

      it 'passes down options to r.run()' do
        SimpleDocument.raw.count.keys.should include "profile"

        NoBrainer.run_with(:profile => false) do
          SimpleDocument.raw.count.should == 1
        end
      end
    end
  end
end
