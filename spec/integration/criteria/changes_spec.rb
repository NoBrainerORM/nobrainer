# frozen_string_literal: true

require 'spec_helper'

describe 'changes' do
  before { load_simple_document }
  before { SimpleDocument.count } # ensure the table is created
  before { NoBrainer.configure { |c| c.per_thread_connection = true } } unless ENV['EM'] == 'true'

  let!(:recorded_changes) { [] }
  after { @thread.try(:kill) } # FIXME leaking connections :)

  def record_changes
    return em_record_changes if ENV['EM'] == 'true'

    @thread = Thread.new do
      begin
        query.changes(:squash => false, :include_states => true).each do |data|
          recorded_changes << data
        end
      rescue Exception => e
        @exception = e
      end
    end
    eventually do
      raise @exception if @exception
      recorded_changes.size.should_not == 0 # state => ready
    end
  end

  def em_record_changes
    Fiber.new do
      begin
        query.changes(:squash => false, :include_states => true).each do |data|
          recorded_changes << data
        end
      rescue Exception => e
        @exception = e
      end
    end.resume

    eventually do
      raise @exception if @exception
      recorded_changes.size.should_not == 0
    end
  end

  context 'on a regular query' do
    let(:query) { SimpleDocument.raw }

    it 'reports changes' do
      record_changes
      recorded_changes.clear

      doc = SimpleDocument.create(:field1 => 123)
      doc.update(:field1 => 456)

      eventually { recorded_changes.size.should == 2 }

      recorded_changes[0]['old_val'].should == nil
      recorded_changes[0]['new_val']['field1'].should == 123

      recorded_changes[1]['old_val']['field1'].should == 123
      recorded_changes[1]['new_val']['field1'].should == 456
    end
  end

  context 'on get_all queries' do
    let!(:doc1) { SimpleDocument.create(:field1 => 1) }
    let!(:doc2) { SimpleDocument.create(:field1 => 2) }

    let(:ids) { [doc1.pk_value, doc2.pk_value] }
    let(:query) { SimpleDocument.raw.where(SimpleDocument.pk_name.in => ids) }

    it 'reports changes' do
      record_changes
      recorded_changes.clear

      doc1.update(:field1 => 11)
      doc2.update(:field1 => 22)

      eventually { recorded_changes.size.should == 2 }

      recorded_changes[0]['old_val']['field1'].should == 1
      recorded_changes[0]['new_val']['field1'].should == 11

      recorded_changes[1]['old_val']['field1'].should == 2
      recorded_changes[1]['new_val']['field1'].should == 22
    end
  end
end
