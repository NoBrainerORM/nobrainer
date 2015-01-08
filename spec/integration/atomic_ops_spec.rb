require 'spec_helper'

describe 'atomic ops' do
  before { load_simple_document }
  before { SimpleDocument.field :field1, :default => 0 }

  let(:doc) { SimpleDocument.create }

  context 'when using queue_atomic' do
    it 'increments' do
      doc

      doc1 = SimpleDocument.first
      doc2 = SimpleDocument.first

      doc1.queue_atomic { doc1.field1 += 1 }
      doc2.queue_atomic { doc2.field1 += 1 }

      doc1.save
      doc2.save

      doc.reload
      doc.field1.should == 2
    end

    it 'increments' do
      doc.queue_atomic do
        doc.field1 += 3
        doc.field1 += 10
        doc.field1 -= 6
        doc.field1 += 8
      end

      doc.save
      doc.reload
      doc.field1.should == 15
    end
  end

  context 'when using aliases' do
    before { SimpleDocument.field :field1, :store_as => :f1 }

    it 'aliases' do
      doc.queue_atomic do
        doc.field1 -= 1
      end

      doc.save
      doc.reload
      doc.field1.should == -1
    end
  end

  context 'when not using the original value' do
    it 'operates on the user value' do
      doc.field1 = ['foo']

      doc.queue_atomic do
        doc.field1 += ['bar']
      end

      doc.save
      doc.reload
      doc.field1.should == %w(foo bar)
    end
  end

  context 'when using dynamic attributes' do
    before do
      SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
    end

    it 'increments' do
      doc['some_field'] = 0
      doc.save

      doc.queue_atomic do
        doc['some_field'] += 1
      end
      doc.save

      SimpleDocument.raw.first['some_field'].should == 1
    end
  end

  context 'when using arrays' do
    before { SimpleDocument.field :field1, :type => Array, :default => [] }

    it 'appends with <<' do
      doc.queue_atomic do
        doc.field1 << 'foo'
        doc.field1 << 'bar'
        doc.field1 << 'foo'
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == %w(foo bar foo)
    end

    it 'appends with +' do
      doc.queue_atomic do
        doc.field1 += ['foo', 'bar']
        doc.field1 += ['hello', 'world', 'foo']
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == %w(foo bar hello world foo)
    end

    it 'removes with -' do
      doc.queue_atomic do
        doc.field1 += ['foo', 'bar']
        doc.field1 += ['hello', 'world', 'foo']
        doc.field1 -= ['foo', 'hello']
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == %w(bar world)
    end

    it 'intersects with -' do
      doc.queue_atomic do
        doc.field1 += ['foo', 'bar']
        doc.field1 += ['hello', 'world', 'foo']
        doc.field1 -= ['foo', 'hello']
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == %w(bar world)
    end
  end

  context 'when using sets' do
    before { SimpleDocument.field :field1, :type => Set, :default => [] }

    it 'appends with <<' do
      doc.queue_atomic do
        doc.field1 << 'foo'
        doc.field1 << 'bar'
        doc.field1 << 'foo'
      end
      doc.save

      SimpleDocument.raw.first['field1'].should =~ %w(foo bar)
    end

    it 'appends with +' do
      doc.queue_atomic do
        doc.field1 += ['foo', 'bar']
        doc.field1 += ['hello', 'world', 'foo']
      end
      doc.save

      SimpleDocument.raw.first['field1'].should =~ %w(foo bar hello world)
    end

    it 'removes with -' do
      doc.queue_atomic do
        doc.field1 += ['foo', 'bar']
        doc.field1 += ['hello', 'world', 'foo']
        doc.field1 -= ['foo', 'hello']
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == %w(bar world)
    end
  end

  context 'atomic block restrictions' do
    context 'when using .save' do
      it 'raises' do
        doc.queue_atomic do
          expect { doc.save }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may persist documents only outside of queue_atomic blocks/)
        end
      end
    end

    context 'when accessing another document' do
      it 'raises' do
        other_doc = SimpleDocument.new
        doc.queue_atomic do
          expect { other_doc.attributes }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
          expect { other_doc.field1 }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
          expect { other_doc.field1 = nil }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
        end
      end
    end

    context 'when reading a doc from the db' do
      it 'raises' do
        doc.queue_atomic do
          expect { SimpleDocument.first }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
        end
      end
    end

    context 'when using non atomic operations' do
      it 'raises' do
        doc.queue_atomic do
          expect { doc.field1 = 'x' }.to raise_error(NoBrainer::Error::AtomicBlock,
            /Avoid the use of atomic blocks for non atomic operations/)
        end
      end
    end

    context 'when using atomic operations outside a block' do
      it 'raises' do
        expect { doc.field1 = doc.queue_atomic { doc.field1 } }.to raise_error(NoBrainer::Error::AtomicBlock,
          /Use atomic blocks for atomic operations/)
      end
    end
  end

  context 'when using validators' do
    before { SimpleDocument.field :field1, :type => Integer, :validates => { numericality: true } }

    it 'skip validations on atomic ops' do
      doc.queue_atomic do
        doc.field1 += 10
      end
      doc.save
      doc.reload
      doc.field1.should == 10
    end
  end

  context 'when saving' do
    before { SimpleDocument.field :field1, :default => 0, :type => Integer }
    before { SimpleDocument.field :field2, :default => [], :type => Array }

    it 'resets the dirty tracking' do
      doc.queue_atomic { doc.field1 += 10 }
      doc.save
      doc.queue_atomic { doc.field1 += 10 }
      doc.save
      doc.reload
      doc.field1.should == 20

      doc.queue_atomic { doc.field2 << 'x' }
      doc.save
      doc.queue_atomic { doc.field2 << 'y' }
      doc.save
      doc.reload
      doc.field2.should == ['x', 'y']
    end
  end

  context 'when assigning multiple variables' do
    it 'works as expected with scalars' do
      doc

      doc.queue_atomic do
        doc.field1 = doc.field1 + 1
        doc.field2 = doc.field1 * 2
      end

      doc.save
      doc.reload

      doc.field1.should == 1
      doc.field2.should == 2
    end

    it 'works as expected with arrays' do
      doc.update(:field1 => [])

      doc.queue_atomic do
        doc.field1 = doc.field1 + [1]
        doc.field2 = doc.field1
        doc.field3 = doc.field1.dup
        doc.field1 << 2
      end

      doc.save
      doc.reload

      doc.field1.should == [1,2]
      doc.field2.should == [1,2]
      doc.field3.should == [1]
    end

    it 'works as expected when exchanging variables' do
      doc.update(:field1 => [], :field2 => [])

      doc.queue_atomic do
        doc.field2, doc.field1 = doc.field1, doc.field2
        doc.field1 << 1
        doc.field2 << 2
        doc.field2, doc.field1 = doc.field1, doc.field2
        doc.field1 << 1
        doc.field2 << 2
      end

      doc.save
      doc.reload

      doc.field1.should == [2,1]
      doc.field2.should == [1,2]
    end
  end

  context 'when the source field is undefined' do
    context 'with integers' do
      before { SimpleDocument.field :field2, :type => Integer }
      it 'defaults to a sane value' do
        doc.queue_atomic { doc.field2 += 1 }
        doc.save
        doc.reload
        doc.field2.should == 1
      end
    end

    context 'with arrays' do
      before { SimpleDocument.field :field2, :type => Array }
      it 'defaults to a sane value, when using +=' do
        doc.queue_atomic { doc.field2 += [1] }
        doc.save
        doc.reload
        doc.field2.should == [1]
      end

      it 'defaults to a sane value, when using <<' do
        doc.queue_atomic { doc.field2 << 1 }
        doc.save
        doc.reload
        doc.field2.should == [1]
      end
    end

    context 'with sets' do
      before { SimpleDocument.field :field2, :type => Set }
      it 'defaults to a sane value, when using +=' do
        doc.queue_atomic { doc.field2 += [1] }
        doc.save
        doc.reload
        doc.field2.should == Set.new([1])
      end

      it 'defaults to a sane value, when using <<' do
        doc.queue_atomic { doc.field2 << 1 }
        doc.save
        doc.reload
        doc.field2.should == Set.new([1])
      end
    end

    context 'with strings' do
      before { SimpleDocument.field :field2, :type => String }
      it 'defaults to a sane value, when using +=' do
        doc.queue_atomic { doc.field2 += 'xxx' }
        doc.save
        doc.reload
        doc.field2.should == 'xxx'
      end
    end

    context 'with no types' do
      before { SimpleDocument.field :field2 }
      it 'does not do something stupid with +=' do
        expect { doc.queue_atomic { doc.field2 += 1 }; doc.save }.to raise_error(/No attribute.*in object/)
      end
      it 'does not do something stupid with <<' do
        expect { doc.queue_atomic { doc.field2 << 1 }; doc.save }.to raise_error(/No attribute.*in object/)
      end
    end
  end
end
