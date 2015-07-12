require 'spec_helper'

describe NoBrainer::Lock do
  let(:lock1) { NoBrainer::Lock.new(:some_key) }
  let(:lock2) { NoBrainer::Lock.new(:some_key) }

  it 'locks with try_lock' do
    lock1.try_lock.should == true
    lock2.try_lock.should == false
    lock1.unlock
    lock2.try_lock.should == true
  end

  it 'locks with synchronize and a block' do
    lock1.synchronize do
      lock2.try_lock.should == false
    end
    lock2.try_lock.should == true
  end

  it 'does not accept weird keys' do
    expect { NoBrainer::Lock.new(1) }.to raise_error(ArgumentError)
  end

  it 'lock/refresh/unlock methods return nil' do
    lock1.lock.should == nil
    lock1.refresh.should == nil
    lock1.unlock.should == nil
  end

  it 'prevents locking twice' do
    lock1.lock
    expect { lock1.lock }.to raise_error(/already locked/)
  end

  it 'prevents unlocking an unlocked lock' do
    expect { lock1.unlock }.to raise_error(/not locked/)
  end

  it 'prevents refreshing when not locked' do
    expect { lock1.refresh }.to raise_error(/not locked/)
  end

  it 'times out if it cannot get the lock' do
    lock1.lock(:expire => 10)
    expect { lock2.lock(:timeout => 0.5) }.to raise_error(NoBrainer::Error::LockUnavailable)
  end

  it 'steals the lock if necessary' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    expect { lock1.unlock }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'refreshes locks' do
    lock1.lock(:expire => 0.2)
    lock1.refresh
    expect { lock2.lock(:timeout => 1) }.to raise_error(NoBrainer::Error::LockUnavailable)
  end

  it 'does not allow refresh to happen on a lost lock' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'allows recovering expired locks' do
    lock1.lock(:expire => 0.1)
    sleep 0.1
    expired_lock = NoBrainer::Lock.expired.first
    expired_lock.lock
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'prevents save/update/delete/destroy' do
    expect { lock1.save        }.to raise_error(NotImplementedError)
    expect { lock1.update({})  }.to raise_error(NotImplementedError)
    expect { lock1.delete      }.to raise_error(NotImplementedError)
    expect { lock1.destroy     }.to raise_error(NotImplementedError)
  end
end
