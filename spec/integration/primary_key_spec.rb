require 'spec_helper'

describe 'NoBrainer id' do
  before { load_simple_document }

  it 'can be used to order documents by time' do
    range = (0..20)
    allow(Time).to receive(:now).and_return(*range.map { |i| Time.at(i) })
    range.each { |i| SimpleDocument.create(:field1 => i) }
    SimpleDocument.all.order_by(SimpleDocument.pk_name => :asc).map(&:field1).to_a.should == range.to_a
  end

  it 'allow custom primary key' do
    SimpleDocument.method_defined?(NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME).should == true
    SimpleDocument.field :some_id, :primary_key => true, :default => -> { 'some_value' }
    SimpleDocument.method_defined?(NoBrainer::Document::PrimaryKey::DEFAULT_PK_NAME).should == false

    doc = SimpleDocument.create
    doc.some_id.should == 'some_value'

    SimpleDocument.field :some_other_id, :primary_key => true
    doc1 = SimpleDocument.create
    doc2 = SimpleDocument.create
    doc1.some_other_id.should_not == 'some_value'
    doc1.should_not == doc2
  end

  context 'when aliasing the primary key' do
    before { NoBrainer.drop! }
    after  { NoBrainer.drop! }

    it 'allow aliasing the primary key' do
      SimpleDocument.field :some_id, :primary_key => true, :store_as => :aliased_id
      doc = SimpleDocument.create
      doc.some_id.should =~ /^[0-9a-zA-Z]{14}$/
      SimpleDocument.where(:some_id => doc.some_id).count.should == 1
      SimpleDocument.raw.first['aliased_id'].should == doc.some_id
    end
  end
end
