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
      doc.update(:field1 => 'hello')
      SimpleDocument.first.field1.should == 'hello!'
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
      doc.update(:field1 => 1)
      SimpleDocument.first.field1.should == '1'
    end
  end
end
