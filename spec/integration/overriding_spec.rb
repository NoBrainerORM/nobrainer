require 'spec_helper'

describe 'NoBrainer layers' do
  before { load_models }

  context 'when overriding a field getter' do
    it 'supports super' do
      BasicModel.class_eval do
        def field1
          "#{super}!"
        end
      end

      doc = BasicModel.new(:field1 => 'ohai')
      doc.field1.should == 'ohai!'
      doc.save
      BasicModel.first.field1.should == 'ohai!'
      doc.update_attributes(:field1 => 'hello')
      BasicModel.first.field1.should == 'hello!'
    end
  end

  context 'when overriding a field setter' do
    it 'supports super' do
      BasicModel.class_eval do
        def field1=(value)
          super "#{value}!"
        end
      end

      # TODO Dry this up: shared example or simple method?
      doc = BasicModel.new(:field1 => 'ohai')
      doc.field1.should == 'ohai!'
      doc.save
      BasicModel.first.field1.should == 'ohai!'
      doc.update_attributes(:field1 => 'hello')
      BasicModel.first.field1.should == 'hello!'
    end
  end
end
