require 'spec_helper'

describe 'NoBrainer persistance' do
  before { load_simple_document }

  let!(:doc) { SimpleDocument.create(:field1 => 'hello', :field2 => 'world') }

  it 'persist fields on creation' do
    doc.reload
    doc.field1.should == 'hello'
    doc.field2.should == 'world'
  end

  it 'persist fields with create!' do
    SimpleDocument.create!(:field1 => 'create!')
    SimpleDocument.where(:field1 => 'create!').count.should == 1
  end

  it 'updates with save' do
    doc.field1 = 'ohai'
    doc.field2 = ':)'
    doc.save
    doc.reload
    doc.field1.should == 'ohai'
    doc.field2.should == ':)'
  end

  it 'updates with update' do
    doc.update(:field1 => 'please', :field2 => 'halp')
    doc.reload
    doc.field1.should == 'please'
    doc.field2.should == 'halp'
  end

  it 'deletes' do
    doc.delete.should == true
    SimpleDocument.find?(doc.pk_value).should == nil
  end

  context 'when using default reload' do
    it 'reloads and cleans up ivars' do
      doc.instance_eval { @some_ivar = true }
      doc.field2 = 'brave world'
      doc.reload.should == doc
      doc.field2.should == 'world'
      doc.instance_eval { @some_ivar }.should == nil
    end
  end

  context 'when using reload with keep_ivars' do
    it 'reloads and cleans up ivars' do
      doc.instance_eval { @some_ivar = true }
      doc.field2 = 'brave world'
      doc.reload(:keep_ivars => true).should == doc
      doc.field2.should == 'world'
      doc.instance_eval { @some_ivar }.should == true
    end
  end

  context 'when the document is gone' do
    before { SimpleDocument.delete_all }
    it 'raises when reloading' do
      expect { doc.reload }.to raise_error(NoBrainer::Error::DocumentNotFound)
    end

    it 'does not raise when updating' do
      expect { doc.update(:field1 => 'x') }.to_not raise_error
    end

    it 'does not raise when deleting' do
      expect { doc.delete }.to_not raise_error
    end
  end

  it 'destroys' do
    doc.destroy.should == true
    SimpleDocument.find?(doc.pk_value).should == nil
  end

  context "when the document already exists" do
    before { NoBrainer.logger.level = Logger::FATAL }

    it 'raises an error when creating' do
      expect { SimpleDocument.create(SimpleDocument.pk_name => doc.pk_value) }
        .to raise_error(NoBrainer::Error::DocumentNotPersisted)
    end
  end
end

describe 'NoBrainer bulk inserts' do
  before { load_simple_document }

  context 'when using insert_all' do
    it 'inserts a bunch of documents' do
      keys = SimpleDocument.insert_all(100.times.map { |i| {:field1 => i+1} })
      SimpleDocument.where(SimpleDocument.pk_name => keys.first).count.should == 1
      SimpleDocument.count.should == 100
      SimpleDocument.where(:field1.gt 50).count.should == 50
    end
  end
end

describe 'sync' do
  before { load_simple_document }

  it 'syncs' do
    # This one is a little hard to test...
    SimpleDocument.sync.should == true
  end
end
