require 'spec_helper'

describe 'NoBrainer layers' do
  before { load_simple_document }

  context 'when overriding a field getter' do
    it 'supports super' do
      SimpleDocument.class_eval do
        def field1
          "#{super}!"
        end
      end

      doc = SimpleDocument.new(:field1 => 'ohai')
      doc.field1.should == 'ohai!'
      doc.save
      SimpleDocument.first.field1.should == 'ohai!'
      doc.update_attributes(:field1 => 'hello')
      SimpleDocument.first.field1.should == 'hello!'
    end
    
    it 'supports accessing the original value' do
      SimpleDocument.class_eval do
        def field1
          "#{self['field1']}!"
        end
      end
      
      doc = SimpleDocument.new(:field1 => 'ohai')
      doc.field1.should == 'ohai!'
      doc.save
    end
  end

  context 'when overriding a field setter' do
    it 'supports super' do
      SimpleDocument.class_eval do
        def field1=(value)
          super(value.to_s)
        end
      end

      # TODO Dry this up: shared example or simple method?
      doc = SimpleDocument.new(:field1 => 1)
      doc.field1.should == '1'
      doc.save
      SimpleDocument.first.field1.should == '1'
      doc.update_attributes(:field1 => 1)
      SimpleDocument.first.field1.should == '1'
    end
    
    it 'supports setting the original value' do
      SimpleDocument.class_eval do
        def field1=(value)
          self[:field1] = "#{value}!"
        end
      end
      
      doc = SimpleDocument.new(:field1 => 1)
      doc.field1.should == '1!'
      doc['field1'] = 2
      doc.field1.should == 2       
      doc.field1 = 3
      doc.field1.should == '3!'
    end
  end
end
