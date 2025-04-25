# frozen_string_literal: true

require 'spec_helper'

describe NoBrainer::Lock do # rubocop:disable RSpec/SpecFilePathFormat
  let(:lock1) { described_class.new(:some_key) }
  let(:lock2) { described_class.new(:some_key) }

  it 'locks with try_lock' do
    expect(lock1.try_lock).to be_truthy
    expect(lock2.try_lock).to be_falsy

    lock1.unlock
    expect(lock2.try_lock).to be_truthy
  end

  it 'locks with synchronize and a block' do
    lock1.synchronize { expect(lock2.try_lock).to be_falsy }

    expect(lock2.try_lock).to be_truthy
  end

  it 'does not accept weird keys' do
    expect { described_class.new(1) }.to raise_error(ArgumentError)
  end

  it 'lock/refresh/unlock methods return nil', retry: 2, retry_wait: 1 do
    expect(lock1.lock).to be_nil
    expect(lock1.refresh).to be_nil
    expect(lock1.unlock).to be_nil
  end

  it 'prevents locking twice' do
    lock1.lock
    expect { lock1.lock }.to raise_error(NoBrainer::Error::LockInvalidOp, /already locked/)
  end

  it 'prevents unlocking an unlocked lock' do
    expect { lock1.unlock }.to raise_error(NoBrainer::Error::LockInvalidOp, /not locked/)
  end

  it 'prevents refreshing when not locked' do
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LockInvalidOp, /not locked/)
  end

  it 'times out if it cannot get the lock' do
    lock1.lock(:expire => 10)
    expect { lock2.lock(:timeout => 0.5) }.to raise_error(NoBrainer::Error::LockUnavailable)
  end

  it 'does not timeout if it can get the lock' do
    lock1.lock(:timeout => 0.1)
    lock1.unlock
    lock1.lock(:timeout => 0)
    lock1.unlock
  end

  it 'steals the lock if necessary' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    expect { lock1.unlock }.to raise_error(NoBrainer::Error::LostLock)
    lock2.unlock
    expect(described_class.count).to be_zero
  end

  it 'steals the lock if necessary 2' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    lock2.unlock
    expect { lock1.unlock }.to raise_error(NoBrainer::Error::LostLock)
    expect(described_class.count).to be_zero
  end

  it 'refreshes locks' do
    lock1.lock(:expire => 0.2)
    lock1.refresh(:expire => 60)
    expect { lock2.lock(:timeout => 1) }.to raise_error(NoBrainer::Error::LockUnavailable)
  end

  it 'does not allow refresh to happen on a lost lock' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'does not allow refresh to happen on a lost lock 2' do
    lock1.lock(:expire => 0.2)
    lock2.lock
    lock2.unlock
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'allows recovering expired locks', retry: 1 do
    lock1.lock(:expire => 0.1)
    sleep 0.1
    expired_lock = described_class.expired.first
    expect(expired_lock).to be_present
    expired_lock.lock
    expect { lock1.refresh }.to raise_error(NoBrainer::Error::LostLock)
  end

  it 'prevents save/update/delete/destroy' do
    expect { lock1.save        }.to raise_error(NotImplementedError)
    expect { lock1.update({})  }.to raise_error(NotImplementedError)
    expect { lock1.delete      }.to raise_error(NotImplementedError)
    expect { lock1.destroy     }.to raise_error(NotImplementedError)
  end

  context 'when specifying default expire value' do
    it 'uses the expires default value' do
      lock1 = described_class.new(:some_key, :expire => 0.1)
      lock1.lock
      lock2 = described_class.new(:some_key)
      lock2.lock
      expect { lock1.unlock }.to raise_error(NoBrainer::Error::LostLock)
    end
  end

  context 'when specifying default timeout value' do
    it 'uses the expires default value' do
      lock1 = described_class.new(:some_key)
      lock1.lock
      lock2 = described_class.new(:some_key, :timeout => 0)
      expect { lock2.lock }.to raise_error(NoBrainer::Error::LockUnavailable)
    end
  end

  context 'when looking for a lock' do
    it 'finds it by key' do
      lock1.lock
      expect(described_class.find(lock1.key)).to eql lock1
    end
  end
end
