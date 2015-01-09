require 'spec_helper'

# FIXME We are not really testing that many connections are gettings used, but
# at least it will exercice the code.

describe 'connection' do
  before { load_simple_document }

  context 'with a single connection' do
    before { NoBrainer.configure { |c| c.per_thread_connection = false } }

    it 'works well' do
      10.times.map { Thread.new { SimpleDocument.count.should == 0 } }.each(&:join)
    end
  end

  context 'with a many connections' do
    before { NoBrainer.configure { |c| c.per_thread_connection = false } }

    it 'works well' do
      10.times.map { Thread.new { SimpleDocument.count.should == 0 } }.each(&:join)
    end
  end
end
