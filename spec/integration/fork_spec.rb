require 'spec_helper'

unless NoBrainer.jruby?
  describe 'fork' do
    it 'disconnects pre-fork' do
      c = NoBrainer.connection
      NoBrainer.connection.should == c
      fork { }
      NoBrainer.connection.should_not == c
    end
  end
end
