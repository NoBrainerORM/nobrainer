require 'spec_helper'

describe 'extend' do
  before { load_simple_document }

  let!(:docs) { 10.times.map { |i| SimpleDocument.create(:field1 => i) } }

  context 'when using a module' do
    before do
      define_module :HelloWorldExtension do
        def hello_world
          :hello_world
        end

        def filter_on_field1(value)
          where(:field1 => value)
        end
      end
    end

    let(:extended_criteria) { SimpleDocument.all.extend(HelloWorldExtension) }

    it 'extends' do
      extended_criteria.hello_world.should == :hello_world
      extended_criteria.filter_on_field1(3).count.should == 1
      extended_criteria.where(:field1 => 1).hello_world.should == :hello_world
      extended_criteria.where(:field1 => 1).filter_on_field1(3).count.should == 0
    end
  end

  context 'when using multiple modules' do
    before do
      define_module(:Mod1) { def mod1; :mod1; end }
      define_module(:Mod2) { def mod2; :mod2; end }
    end

    it 'extends' do
      SimpleDocument.all.extend(Mod1, Mod2).where().mod1.should == :mod1
      SimpleDocument.all.extend(Mod1, Mod2).where().mod2.should == :mod2

      SimpleDocument.all.extend(Mod1).extend(Mod2).mod1.should == :mod1
      SimpleDocument.all.extend(Mod1).extend(Mod2).mod2.should == :mod2

      old_criteria = SimpleDocument.all.extend(Mod1).extend(Mod2)
      new_criteria = old_criteria.extend { def mod2; :hello_world; end }
      new_criteria.mod2.should == :hello_world
      old_criteria.mod2.should == :mod2
    end
  end
end
