require 'spec_helper'

# FIXME We are not really testing that many connections are gettings used, but
# at least it will exercice the code.

unless ENV['EM']
  describe 'connection' do
    before { load_simple_document }
    before { SimpleDocument.count } # ensure the table is created

    context 'with a single connection' do
      before { NoBrainer.configure { |c| c.per_thread_connection = false } }

      it 'works well' do
        10.times.map { Thread.new { 5.times { SimpleDocument.count.should == 0 } } }.each(&:join)
      end
    end

    context 'with many connections' do
      before { NoBrainer.configure { |c| c.per_thread_connection = true } }

      it 'works well' do
        10.times.map { Thread.new { 5.times { SimpleDocument.count.should == 0 } } }.each(&:join)
      end
    end
  end
end

describe 'NoBrainer::Connection.parse_uri' do
  let(:connection) { NoBrainer::Connection.new }
  let(:auth_key) { 'rethinkdb://:abcd@localhost:1234/db' }
  let(:user) { 'rethinkdb://user:pass@localhost:1234/db' }

  it 'parses token auth' do
    connection = NoBrainer::Connection.new(auth_key)
    expect(connection.parsed_uri[:auth_key]).to eq('abcd')
  end

  it 'parses user auth' do
    connection = NoBrainer::Connection.new(user)
    expect(connection.parsed_uri.slice(:user, :password).values).to eq(['user', 'pass'])
  end
end

describe 'NoBrainer.run' do
  it 'works well' do
    NoBrainer.run { |r| r.expr(3) }.should == 3
    NoBrainer.run { |r| r.expr([1,2,3]) }.should == [1,2,3]
  end
end
